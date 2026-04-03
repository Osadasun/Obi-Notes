//
//  AddToListViewModel.swift
//  Obi
//
//  リスト追加画面のViewModel
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AddToListViewModel: ObservableObject {
    @Published var lists: [MusicList] = []
    @Published var sortedLists: [MusicList] = [] // ピン留めとアクティビティ順でソート
    @Published var addedListIds: Set<UUID> = []
    @Published var listCounts: [UUID: Int] = [:] // リストの件数を保持
    @Published var listArtworks: [UUID: [String?]] = [:] // リストのアートワークを保持
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared
    private var listLatestDates: [UUID: Date] = [:] // リストの最新アクティビティ日付
    var obiListViewModel: ObiListViewModel? = nil // ピン留め情報を取得

    let targetType: TargetType
    let targetId: String
    let title: String
    let artist: String
    let artworkURL: String?

    init(targetType: TargetType, targetId: String, title: String, artist: String, artworkURL: String?, obiListViewModel: ObiListViewModel? = nil) {
        self.targetType = targetType
        self.targetId = targetId
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
        self.obiListViewModel = obiListViewModel
    }

    // MARK: - Computed Properties

    var defaultLists: [MusicList] {
        lists.filter { $0.defaultType != nil }
    }

    var customLists: [MusicList] {
        lists.filter { $0.defaultType == nil }
    }

    // MARK: - Load Lists

    func loadLists() async {
        isLoading = true
        errorMessage = nil

        do {
            // ユーザーの全リストを取得
            lists = try await supabaseService.fetchUserLists()

            // 既に追加されているリストをチェック
            await checkAddedLists()

            // ソート実行
            sortLists()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ リスト取得エラー: \(error)")
        }

        isLoading = false
    }

    // MARK: - Sort Lists

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

        // ピン留めとアクティビティ日付を考慮してソート（ObiViewと同じロジック）
        sortedLists = lists.sorted { list1, list2 in
            let itemId1 = "list-\(list1.id)"
            let itemId2 = "list-\(list2.id)"
            let isPinned1 = obiListViewModel.isPinned(itemId: itemId1)
            let isPinned2 = obiListViewModel.isPinned(itemId: itemId2)

            // ピン留めされているリストが優先
            if isPinned1 && !isPinned2 {
                return true
            } else if !isPinned1 && isPinned2 {
                return false
            } else if isPinned1 && isPinned2 {
                // 両方ピン留めされている場合は、ピン留めした順序
                let pinnedIds = obiListViewModel.pinnedItemIds
                let index1 = pinnedIds.firstIndex(of: itemId1) ?? 0
                let index2 = pinnedIds.firstIndex(of: itemId2) ?? 0
                return index1 < index2
            } else {
                // 両方ピン留めされていない場合は、最新日付順
                let date1 = listLatestDates[list1.id] ?? list1.createdAt
                let date2 = listLatestDates[list2.id] ?? list2.createdAt
                return date1 > date2
            }
        }
    }

    // MARK: - Check Added Lists

    private func checkAddedLists() async {
        do {
            // 各リストに対して、このアイテムが含まれているかチェック
            var addedIds: Set<UUID> = []
            var counts: [UUID: Int] = [:]
            var artworks: [UUID: [String?]] = [:]
            var latestDates: [UUID: Date] = [:]

            for list in lists {
                let items = try await supabaseService.fetchListItems(listId: list.id)
                counts[list.id] = items.count
                artworks[list.id] = items.prefix(3).map { $0.albumArt }

                // 最新のアイテム追加日を取得（リスト作成日と比較）
                let latestItemDate = items.map { $0.addedAt }.max()
                let latestActivityDate = max(list.createdAt, latestItemDate ?? list.createdAt)
                latestDates[list.id] = latestActivityDate

                if items.contains(where: { $0.targetId == targetId }) {
                    addedIds.insert(list.id)
                }
            }

            addedListIds = addedIds
            listCounts = counts
            listArtworks = artworks
            listLatestDates = latestDates
        } catch {
            print("❌ リストアイテムチェックエラー: \(error)")
        }
    }

    // MARK: - Helper Methods

    func iconForList(_ list: MusicList) -> String {
        guard let defaultType = list.defaultType else {
            return "music.note.list"
        }

        switch defaultType {
        case .reviewed: return "music.note.list"
        case .favorite: return "heart.fill"
        case .listened: return "headphones"
        case .wishlist: return "star.fill"
        }
    }

    func colorForList(_ list: MusicList) -> Color {
        guard let defaultType = list.defaultType else {
            return .purple
        }

        switch defaultType {
        case .reviewed: return .purple
        case .favorite: return .pink
        case .listened: return .blue
        case .wishlist: return .orange
        }
    }

    // MARK: - Toggle List

    func toggleList(_ list: MusicList) async {
        do {
            if addedListIds.contains(list.id) {
                // リストから削除
                try await supabaseService.removeFromList(
                    listId: list.id,
                    targetId: targetId
                )
                addedListIds.remove(list.id)
                print("✅ リストから削除: \(list.name)")
            } else {
                // リストに追加
                try await supabaseService.addToList(
                    listId: list.id,
                    targetType: targetType,
                    targetId: targetId,
                    title: title,
                    artist: artist,
                    artworkURL: artworkURL
                )
                addedListIds.insert(list.id)
                print("✅ リストに追加: \(list.name)")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ リスト操作エラー: \(error)")
        }
    }
}
