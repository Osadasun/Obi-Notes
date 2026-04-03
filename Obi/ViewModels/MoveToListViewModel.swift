//
//  MoveToListViewModel.swift
//  Obi
//
//  リスト/アルバム移動用ViewModel
//

import Foundation
import Combine

@MainActor
class MoveToListViewModel: ObservableObject {
    @Published var lists: [MusicList] = []
    @Published var sortedLists: [MusicList] = [] // ピン留めとアクティビティ順でソート
    @Published var selectedList: MusicList?
    @Published var isLoading = false
    @Published var isMoving = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared
    private var listLatestDates: [UUID: Date] = [:]
    var obiListViewModel: ObiListViewModel?

    let sourceType: SourceType // 移動元がリストかアルバムか
    let sourceId: String // 移動元のID

    enum SourceType: Identifiable {
        case list(UUID)
        case userAlbum(String)

        var id: String {
            switch self {
            case .list(let uuid):
                return "list-\(uuid.uuidString)"
            case .userAlbum(let id):
                return "album-\(id)"
            }
        }
    }

    init(sourceType: SourceType, obiListViewModel: ObiListViewModel? = nil) {
        switch sourceType {
        case .list(let id):
            self.sourceType = sourceType
            self.sourceId = id.uuidString
        case .userAlbum(let id):
            self.sourceType = sourceType
            self.sourceId = id
        }
        self.obiListViewModel = obiListViewModel
    }

    func loadLists() async {
        print("🔄 [MoveToList] Starting loadLists()")
        isLoading = true
        errorMessage = nil

        guard let userId = UserManager.shared.currentUserId else {
            print("❌ [MoveToList] No user ID found")
            errorMessage = "ログインしてください"
            isLoading = false
            return
        }

        print("ℹ️ [MoveToList] User ID: \(userId)")

        do {
            // 全リストを取得
            lists = try await supabaseService.fetchUserLists(userId: userId)
            print("ℹ️ [MoveToList] Fetched \(lists.count) total lists from DB")

            // 移動元が自分自身の場合は除外
            switch sourceType {
            case .list(let listId):
                print("ℹ️ [MoveToList] Source is list: \(listId)")
                let beforeCount = lists.count
                lists.removeAll { $0.id == listId }
                print("ℹ️ [MoveToList] Removed self from destinations: \(beforeCount) → \(lists.count)")
            case .userAlbum(let albumId):
                print("ℹ️ [MoveToList] Source is album: \(albumId)")
                break // アルバムの場合はリストに移動可能
            }

            // カスタムリストのみフィルタ（デフォルトリストには移動不可）
            let beforeFilterCount = lists.count
            lists = lists.filter { $0.type == .custom }
            print("ℹ️ [MoveToList] Filtered to custom lists only: \(beforeFilterCount) → \(lists.count)")

            // 第一階層（親を持たないリスト）のみに絞る
            let beforeRootFilterCount = lists.count
            lists = lists.filter { $0.parentListId == nil }
            print("ℹ️ [MoveToList] Filtered to root-level lists only: \(beforeRootFilterCount) → \(lists.count)")

            // 各リストの最新アクティビティ日付を計算
            print("ℹ️ [MoveToList] Calculating latest activity dates for \(lists.count) lists...")
            var latestDates: [UUID: Date] = [:]
            for list in lists {
                let items = try await supabaseService.fetchListItems(listId: list.id)
                let latestItemDate = items.map { $0.addedAt }.max()
                let latestActivityDate = max(list.createdAt, latestItemDate ?? list.createdAt)
                latestDates[list.id] = latestActivityDate
                print("  - \(list.name): \(items.count) items, latest: \(latestActivityDate)")
            }
            listLatestDates = latestDates

            // ソート実行
            print("ℹ️ [MoveToList] Sorting \(lists.count) lists...")
            sortLists()
            print("ℹ️ [MoveToList] After sort: sortedLists.count = \(sortedLists.count)")

            print("✅ [MoveToList] Loaded \(lists.count) lists, sorted \(sortedLists.count)")
        } catch {
            print("❌ [MoveToList] Failed to load lists: \(error)")
            errorMessage = "リストの取得に失敗しました"
        }

        isLoading = false
        print("ℹ️ [MoveToList] isLoading = false, lists.count = \(lists.count), sortedLists.count = \(sortedLists.count)")
    }

    private func sortLists() {
        print("🔄 [MoveToList] sortLists() called with \(lists.count) lists")

        guard let obiListViewModel = obiListViewModel else {
            print("ℹ️ [MoveToList] No obiListViewModel, sorting by date only")
            // obiListViewModelがない場合は最新日付順のみ
            sortedLists = lists.sorted { list1, list2 in
                let date1 = listLatestDates[list1.id] ?? list1.createdAt
                let date2 = listLatestDates[list2.id] ?? list2.createdAt
                return date1 > date2
            }
            print("ℹ️ [MoveToList] Sorted lists (date only): \(sortedLists.map { $0.name })")
            return
        }

        print("ℹ️ [MoveToList] Has obiListViewModel, sorting with pin priority")
        // ピン留めとアクティビティ日付を考慮してソート
        sortedLists = lists.sorted { list1, list2 in
            let itemId1 = "list-\(list1.id)"
            let itemId2 = "list-\(list2.id)"
            let isPinned1 = obiListViewModel.isPinned(itemId: itemId1)
            let isPinned2 = obiListViewModel.isPinned(itemId: itemId2)

            if isPinned1 && !isPinned2 {
                return true
            } else if !isPinned1 && isPinned2 {
                return false
            } else if isPinned1 && isPinned2 {
                let pinnedIds = obiListViewModel.pinnedItemIds
                let index1 = pinnedIds.firstIndex(of: itemId1) ?? 0
                let index2 = pinnedIds.firstIndex(of: itemId2) ?? 0
                return index1 < index2
            } else {
                let date1 = listLatestDates[list1.id] ?? list1.createdAt
                let date2 = listLatestDates[list2.id] ?? list2.createdAt
                return date1 > date2
            }
        }
        print("ℹ️ [MoveToList] Sorted lists (with pins): \(sortedLists.map { $0.name })")
    }

    func moveToSelectedList() async -> Bool {
        isMoving = true
        errorMessage = nil

        do {
            let parentListId = selectedList?.id

            switch sourceType {
            case .list(let listId):
                try await supabaseService.moveListToParent(listId: listId, parentListId: parentListId)
                print("✅ [MoveToList] List moved successfully")

            case .userAlbum(let albumId):
                try await supabaseService.moveUserAlbumToParent(albumId: albumId, parentListId: parentListId?.uuidString)
                print("✅ [MoveToList] Album moved successfully")
            }

            isMoving = false
            return true
        } catch {
            print("❌ [MoveToList] Failed to move: \(error)")
            errorMessage = "移動に失敗しました"
            isMoving = false
            return false
        }
    }
}
