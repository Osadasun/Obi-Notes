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

    private let supabaseService = SupabaseService.shared

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

            // カスタムリストを抽出
            var customListsArray: [MusicList] = []

            for list in lists {
                let items = try await supabaseService.fetchListItems(listId: list.id)
                let artworks = items.prefix(3).map { $0.albumArt }

                switch list.defaultType {
                case .reviewed:
                    // レビュー済みは上で計算済み（reviewedCount & reviewedArtworks）
                    break
                case .favorite:
                    favoriteCount = items.count
                    favoriteArtworks = Array(artworks)
                case .listened:
                    listenedCount = items.count
                    listenedArtworks = Array(artworks)
                case .wishlist:
                    wishlistCount = items.count
                    wishlistArtworks = Array(artworks)
                case .none:
                    // カスタムリストの場合
                    if list.type == .custom {
                        customListsArray.append(list)
                        customListCounts[list.id] = items.count
                        customListArtworks[list.id] = Array(artworks)
                    }
                }
            }

            customLists = customListsArray

            // ユーザーアルバムを取得
            let albums = try await supabaseService.fetchUserAlbums(userId: userId.uuidString)
            userAlbums = albums

            // TODO: ユーザーアルバムの曲数を取得する（現在は0件）
            for album in albums {
                userAlbumCounts[album.id] = 0 // 仮の値（実装予定）
            }

            // ObiItemsに統合（カスタムリストとユーザーアルバムをマージ）
            var items: [ObiItem] = []
            items.append(contentsOf: customListsArray.map { .list($0) })
            items.append(contentsOf: albums.map { .userAlbum($0) })
            obiItems = items

            print("✅ リスト件数取得成功: カスタムリスト\(customLists.count)件、ユーザーアルバム\(userAlbums.count)件")
        } catch {
            print("❌ リスト件数取得エラー: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
