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

    enum SourceType {
        case list(UUID)
        case userAlbum(String)
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
        isLoading = true
        errorMessage = nil

        guard let userId = UserManager.shared.currentUserId else {
            errorMessage = "ログインしてください"
            isLoading = false
            return
        }

        do {
            // 全リストを取得
            lists = try await supabaseService.fetchUserLists(userId: userId)

            // 移動元が自分自身の場合は除外
            switch sourceType {
            case .list(let listId):
                lists.removeAll { $0.id == listId }
            case .userAlbum:
                break // アルバムの場合はリストに移動可能
            }

            // カスタムリストのみフィルタ（デフォルトリストには移動不可）
            lists = lists.filter { $0.type == .custom }

            // 各リストの最新アクティビティ日付を計算
            var latestDates: [UUID: Date] = [:]
            for list in lists {
                let items = try await supabaseService.fetchListItems(listId: list.id)
                let latestItemDate = items.map { $0.addedAt }.max()
                let latestActivityDate = max(list.createdAt, latestItemDate ?? list.createdAt)
                latestDates[list.id] = latestActivityDate
            }
            listLatestDates = latestDates

            // ソート実行
            sortLists()

            print("✅ [MoveToList] Loaded \(lists.count) lists")
        } catch {
            print("❌ [MoveToList] Failed to load lists: \(error)")
            errorMessage = "リストの取得に失敗しました"
        }

        isLoading = false
    }

    private func sortLists() {
        guard let obiListViewModel = obiListViewModel else {
            // obiListViewModelがない場合は最新日付順のみ
            sortedLists = lists.sorted { list1, list2 in
                let date1 = listLatestDates[list1.id] ?? list1.createdAt
                let date2 = listLatestDates[list2.id] ?? list2.createdAt
                return date1 > date2
            }
            return
        }

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
