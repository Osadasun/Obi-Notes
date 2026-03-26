//
//  ListDetailViewModel.swift
//  Obi
//
//  リスト詳細画面用ViewModel
//

import Foundation
import Combine

@MainActor
class ListDetailViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared
    private let listType: MyListCategory

    init(listType: MyListCategory) {
        self.listType = listType
    }

    func loadAlbums() async {
        isLoading = true
        errorMessage = nil

        guard let userId = UserManager.shared.currentUserId else {
            errorMessage = "ユーザーが認証されていません"
            isLoading = false
            return
        }

        do {
            switch listType {
            case .reviewed:
                // レビュー済みアルバムを取得
                let reviews = try await supabaseService.fetchMyReviews(userId: userId)

                // ユニークなアルバムのみを取得
                var uniqueAlbums: [String: Review] = [:]
                for review in reviews {
                    if uniqueAlbums[review.targetId] == nil {
                        uniqueAlbums[review.targetId] = review
                    }
                }

                // Albumモデルにマッピング
                albums = uniqueAlbums.values.map { review in
                    Album(
                        id: review.targetId,
                        title: review.title,
                        artist: review.artist,
                        artworkURL: review.albumArt,
                        releaseDate: nil,
                        genre: nil,
                        trackCount: nil
                    )
                }

            case .favorite, .listened, .wishlist:
                // リストからアイテムを取得
                let lists = try await supabaseService.fetchUserLists(userId: userId)

                // 該当するリストを探す
                let defaultListType: DefaultListType
                switch listType {
                case .favorite:
                    defaultListType = .favorite
                case .listened:
                    defaultListType = .listened
                case .wishlist:
                    defaultListType = .wishlist
                case .reviewed:
                    fatalError("Already handled")
                }

                if let targetList = lists.first(where: { $0.defaultType == defaultListType }) {
                    let items = try await supabaseService.fetchListItems(listId: targetList.id)

                    print("📋 [ListDetailViewModel] Fetched \(items.count) items from list")
                    for (index, item) in items.enumerated() {
                        print("   [\(index)] \(item.title) - targetId: \(item.targetId)")
                    }

                    // Albumモデルにマッピング
                    albums = items.map { item in
                        Album(
                            id: item.targetId,
                            title: item.title,
                            artist: item.artist,
                            artworkURL: item.albumArt,
                            releaseDate: nil,
                            genre: nil,
                            trackCount: nil
                        )
                    }

                    print("📋 [ListDetailViewModel] Mapped to \(albums.count) albums")
                } else {
                    albums = []
                }
            }

            print("✅ リスト詳細取得成功: \(albums.count)件")
        } catch {
            print("❌ リスト詳細取得エラー: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
