//
//  CustomListDetailViewModel.swift
//  Obi
//
//  カスタムリスト詳細画面用ViewModel
//

import Foundation
import Combine

@MainActor
class CustomListDetailViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var childLists: [MusicList] = []
    @Published var childUserAlbums: [UserAlbum] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared
    private let listId: UUID

    init(listId: UUID) {
        self.listId = listId
    }

    func loadAlbums() async {
        isLoading = true
        errorMessage = nil

        guard UserManager.shared.currentUserId != nil else {
            errorMessage = "ユーザーが認証されていません"
            isLoading = false
            return
        }

        do {
            // リストアイテムを取得
            let items = try await supabaseService.fetchListItems(listId: listId)

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

            // 子リストを取得
            childLists = try await supabaseService.fetchChildLists(parentListId: listId)

            // 子ユーザーアルバムを取得
            childUserAlbums = try await supabaseService.fetchChildUserAlbums(parentListId: listId.uuidString)

            print("✅ カスタムリストアルバム取得成功: \(albums.count)件, 子リスト: \(childLists.count)件, 子アルバム: \(childUserAlbums.count)件")
        } catch {
            print("❌ カスタムリストアルバム取得エラー: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
