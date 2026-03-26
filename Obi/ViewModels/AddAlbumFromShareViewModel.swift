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
    @Published var lists: [MusicList] = []
    @Published var selectedList: MusicList?
    @Published var isLoading = false
    @Published var isLoadingLists = false
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

    func loadLists() async {
        guard let userId = UserManager.shared.currentUserId else {
            errorMessage = "ログインしてください"
            return
        }

        isLoadingLists = true

        do {
            lists = try await supabaseService.fetchUserLists(userId: userId)
            // デフォルトで「聴いた」リストを選択
            selectedList = lists.first(where: { $0.defaultType == .listened })
            print("✅ [AddAlbumFromShare] Loaded \(lists.count) lists")
        } catch {
            print("❌ [AddAlbumFromShare] Failed to load lists: \(error)")
            errorMessage = "リストの取得に失敗しました"
        }

        isLoadingLists = false
    }

    func addToSelectedList() async {
        guard let album = album else { return }
        guard let list = selectedList else {
            errorMessage = "リストを選択してください"
            return
        }

        isAdding = true
        errorMessage = nil

        do {
            // 重複チェック
            let existingItems = try await supabaseService.fetchListItems(listId: list.id)
            if existingItems.contains(where: { $0.targetId == album.id }) {
                errorMessage = "既にこのリストに追加されています"
                isAdding = false
                return
            }

            // リストに追加
            try await supabaseService.addToList(
                listId: list.id,
                targetType: .album,
                targetId: album.id,
                title: album.title,
                artist: album.artist,
                artworkURL: album.artworkURL300
            )

            print("✅ [AddAlbumFromShare] Album added to list: \(list.name)")
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
