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

            // 各リストの件数を取得
            let lists = try await supabaseService.fetchUserLists(userId: userId)

            // カスタムリストを抽出
            var customListsArray: [MusicList] = []

            for list in lists {
                let items = try await supabaseService.fetchListItems(listId: list.id)

                switch list.defaultType {
                case .reviewed:
                    // レビュー済みは上で計算済み（reviewedCount）
                    break
                case .favorite:
                    favoriteCount = items.count
                case .listened:
                    listenedCount = items.count
                case .wishlist:
                    wishlistCount = items.count
                case .none:
                    // カスタムリストの場合
                    if list.type == .custom {
                        customListsArray.append(list)
                        customListCounts[list.id] = items.count
                    }
                }
            }

            customLists = customListsArray

            print("✅ リスト件数取得成功: カスタムリスト\(customLists.count)件")
        } catch {
            print("❌ リスト件数取得エラー: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
