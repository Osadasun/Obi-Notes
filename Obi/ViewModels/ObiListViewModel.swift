//
//  ObiListViewModel.swift
//  Obi
//
//  リスト管理用ViewModel
//

import Foundation
import Combine

@MainActor
class ObiListViewModel: ObservableObject {
    @Published var reviewedCount: Int = 0
    @Published var favoriteCount: Int = 0
    @Published var listenedCount: Int = 0
    @Published var wishlistCount: Int = 0
    @Published var customLists: [MusicList] = []
    @Published var customListCounts: [UUID: Int] = [:] // カスタムリストの件数を保持
    @Published var reviewedArtworks: [String?] = []
    @Published var favoriteArtworks: [String?] = []
    @Published var listenedArtworks: [String?] = []
    @Published var wishlistArtworks: [String?] = []
    @Published var customListArtworks: [UUID: [String?]] = [:]
    @Published var userAlbums: [UserAlbum] = [] // ユーザーアルバム
    @Published var userAlbumCounts: [String: Int] = [:] // ユーザーアルバムの曲数
    @Published var obiItems: [ObiItem] = [] // リストとアルバムを統合
    @Published var latestReview: Review? = nil // 最新のレビュー
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var pinnedItemIds: [String] = [] // ピン留めされたアイテムのID（最大2件）

    private let supabaseService = SupabaseService.shared
    private let pinnedItemsKey = "obiPinnedItems"

    init() {
        loadPinnedItems()
    }

    // ピン留め情報の読み込み
    private func loadPinnedItems() {
        if let saved = UserDefaults.standard.array(forKey: pinnedItemsKey) as? [String] {
            pinnedItemIds = Array(saved.prefix(2)) // 最大2件
        }
    }

    // ピン留め情報の保存
    private func savePinnedItems() {
        UserDefaults.standard.set(pinnedItemIds, forKey: pinnedItemsKey)
    }

    // ピン留めのトグル
    func togglePin(itemId: String) {
        if pinnedItemIds.contains(itemId) {
            // ピン留め解除
            pinnedItemIds.removeAll { $0 == itemId }
        } else {
            // ピン留め追加（最大2件）
            if pinnedItemIds.count >= 2 {
                // 最も古いピン留めを削除
                pinnedItemIds.removeFirst()
            }
            pinnedItemIds.append(itemId)
        }
        savePinnedItems()

        // 並び替えを再実行
        sortObiItems()
    }

    // アイテムがピン留めされているか確認
    func isPinned(itemId: String) -> Bool {
        pinnedItemIds.contains(itemId)
    }

    // ピン留めと日付を考慮してソート
    private func sortObiItems() {
        obiItems.sort { item1, item2 in
            let isPinned1 = pinnedItemIds.contains(item1.id)
            let isPinned2 = pinnedItemIds.contains(item2.id)

            // ピン留めされているアイテムが優先
            if isPinned1 && !isPinned2 {
                return true
            } else if !isPinned1 && isPinned2 {
                return false
            } else if isPinned1 && isPinned2 {
                // 両方ピン留めされている場合は、ピン留めした順序（pinnedItemIdsの順序）
                let index1 = pinnedItemIds.firstIndex(of: item1.id) ?? 0
                let index2 = pinnedItemIds.firstIndex(of: item2.id) ?? 0
                return index1 < index2
            } else {
                // 両方ピン留めされていない場合は、最新日付順
                return item1.latestDate > item2.latestDate
            }
        }
    }

    func loadListCounts() async {
        isLoading = true
        errorMessage = nil

        guard let userId = UserManager.shared.currentUserId else {
            errorMessage = "ユーザーが認証されていません"
            isLoading = false
            return
        }

        do {
            // レビュー済みアルバム数を取得
            let reviews = try await supabaseService.fetchMyReviews(userId: userId)
            let uniqueAlbums = Set(reviews.map { $0.targetId })
            reviewedCount = uniqueAlbums.count

            // レビューからアートワークを取得（最大3件）
            reviewedArtworks = Array(reviews.prefix(3).map { $0.albumArt })

            // 最新のレビューを保持（ObiCard表示用）
            latestReview = reviews.first

            // 各リストの件数を取得
            let lists = try await supabaseService.fetchUserLists(userId: userId)

            // 全リストを抽出（デフォルト+カスタム）
            var allListsArray: [MusicList] = []
            var customListsArray: [MusicList] = []
            var listLatestDates: [UUID: Date] = [:] // リストの最新アクティビティ日付

            for list in lists {
                let items = try await supabaseService.fetchListItems(listId: list.id)
                let artworks = items.prefix(3).map { $0.albumArt }

                // 最新のアイテム追加日を取得（リスト作成日と比較）
                let latestItemDate = items.map { $0.addedAt }.max()
                let latestActivityDate = max(list.createdAt, latestItemDate ?? list.createdAt)

                switch list.defaultType {
                case .reviewed:
                    // レビュー済みは上で計算済み（reviewedCount & reviewedArtworks）
                    allListsArray.append(list)
                    customListCounts[list.id] = items.count
                    customListArtworks[list.id] = Array(artworks)
                    listLatestDates[list.id] = latestActivityDate
                case .favorite:
                    favoriteCount = items.count
                    favoriteArtworks = Array(artworks)
                    allListsArray.append(list)
                    customListCounts[list.id] = items.count
                    customListArtworks[list.id] = Array(artworks)
                    listLatestDates[list.id] = latestActivityDate
                case .listened:
                    listenedCount = items.count
                    listenedArtworks = Array(artworks)
                    allListsArray.append(list)
                    customListCounts[list.id] = items.count
                    customListArtworks[list.id] = Array(artworks)
                    listLatestDates[list.id] = latestActivityDate
                case .wishlist:
                    wishlistCount = items.count
                    wishlistArtworks = Array(artworks)
                    allListsArray.append(list)
                    customListCounts[list.id] = items.count
                    customListArtworks[list.id] = Array(artworks)
                    listLatestDates[list.id] = latestActivityDate
                case .none:
                    // カスタムリストの場合（親がないトップレベルのみ）
                    if list.type == .custom && list.parentListId == nil {
                        customListsArray.append(list)
                        allListsArray.append(list)
                        customListCounts[list.id] = items.count
                        customListArtworks[list.id] = Array(artworks)
                        listLatestDates[list.id] = latestActivityDate
                    }
                }
            }

            customLists = customListsArray

            // ユーザーアルバムを取得（親がないトップレベルのみ）
            let allAlbums = try await supabaseService.fetchUserAlbums(userId: userId.uuidString)
            let topLevelAlbums = allAlbums.filter { $0.parentListId == nil }
            userAlbums = topLevelAlbums

            // ユーザーアルバムの曲数と最新アクティビティ日付を取得
            var userAlbumLatestDates: [String: Date] = [:] // アルバムの最新アクティビティ日付
            for album in topLevelAlbums {
                let tracks = try await supabaseService.fetchUserAlbumTracks(albumId: album.id)
                userAlbumCounts[album.id] = tracks.count

                // 最新のトラック追加日を取得（アルバム更新日と比較）
                let latestTrackDate = tracks.map { $0.addedAt }.max()
                let latestActivityDate = max(album.updatedAt, latestTrackDate ?? album.updatedAt)
                userAlbumLatestDates[album.id] = latestActivityDate
            }

            // ObiItemsに統合（デフォルトリスト + カスタムリスト + ユーザーアルバムをマージ）
            var items: [ObiItem] = []
            items.append(contentsOf: allListsArray.map { list in
                .list(list, latestActivityDate: listLatestDates[list.id] ?? list.createdAt)
            })
            items.append(contentsOf: topLevelAlbums.map { album in
                .userAlbum(album, latestActivityDate: userAlbumLatestDates[album.id] ?? album.updatedAt)
            })

            obiItems = items
            sortObiItems()

            print("✅ リスト件数取得成功: カスタムリスト\(customLists.count)件、ユーザーアルバム\(userAlbums.count)件")
        } catch {
            print("❌ リスト件数取得エラー: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
