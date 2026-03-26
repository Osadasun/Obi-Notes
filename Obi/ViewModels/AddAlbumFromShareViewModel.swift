//
//  AddAlbumFromShareViewModel.swift
//  Obi
//
//  Share Extensionから開かれたアルバム追加画面のViewModel
//

import Foundation
import Combine

@MainActor
class AddAlbumFromShareViewModel: ObservableObject {
    @Published var album: Album?
    @Published var isLoading = false
    @Published var isAdding = false
    @Published var addSuccess = false
    @Published var errorMessage: String?

    private let albumId: String
    private let appleMusicService = AppleMusicService.shared
    private let supabaseService = SupabaseService.shared

    init(albumId: String) {
        self.albumId = albumId
    }

    func loadAlbum() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📀 [AddAlbumFromShare] Loading album: \(albumId)")
            let fetchedAlbum = try await appleMusicService.fetchAlbum(id: albumId)
            self.album = fetchedAlbum
            print("✅ [AddAlbumFromShare] Album loaded: \(fetchedAlbum.title)")
        } catch {
            print("❌ [AddAlbumFromShare] Failed to load album: \(error)")
            errorMessage = "アルバム情報の取得に失敗しました"
        }

        isLoading = false
    }

    func addToListenedList() async {
        guard let album = album else { return }
        guard let userId = UserManager.shared.currentUserId else {
            errorMessage = "ログインしてください"
            return
        }

        isAdding = true
        errorMessage = nil

        do {
            // 「聴いた」リストを取得
            let lists = try await supabaseService.fetchUserLists(userId: userId)
            guard let listenedList = lists.first(where: { $0.defaultType == .listened }) else {
                errorMessage = "「聴いた」リストが見つかりません"
                isAdding = false
                return
            }

            // 重複チェック
            let existingItems = try await supabaseService.fetchListItems(listId: listenedList.id)
            if existingItems.contains(where: { $0.targetId == album.id }) {
                errorMessage = "既にリストに追加されています"
                isAdding = false
                return
            }

            // リストに追加
            try await supabaseService.addToList(
                listId: listenedList.id,
                targetType: .album,
                targetId: album.id,
                title: album.title,
                artist: album.artist,
                artworkURL: album.artworkURL300
            )

            print("✅ [AddAlbumFromShare] Album added to listened list")
            addSuccess = true

            // App Groupsから削除
            AppGroupManager.shared.removePendingAlbum(albumId: albumId)

        } catch {
            print("❌ [AddAlbumFromShare] Failed to add album: \(error)")
            errorMessage = "追加に失敗しました"
        }

        isAdding = false
    }
}
