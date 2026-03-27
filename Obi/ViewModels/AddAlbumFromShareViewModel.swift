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
    @Published var track: Track?
    @Published var lists: [MusicList] = []
    @Published var userAlbums: [UserAlbum] = []
    @Published var selectedList: MusicList?
    @Published var selectedUserAlbum: UserAlbum?
    @Published var isLoading = false
    @Published var isLoadingLists = false
    @Published var isAdding = false
    @Published var addSuccess = false
    @Published var errorMessage: String?

    private let musicId: String
    private let musicType: MusicTargetType
    private let appleMusicService = AppleMusicService.shared
    private let supabaseService = SupabaseService.shared

    init(musicId: String, musicType: MusicTargetType) {
        self.musicId = musicId
        self.musicType = musicType
    }

    func loadMusic() async {
        isLoading = true
        errorMessage = nil

        do {
            switch musicType {
            case .album:
                print("📀 [AddAlbumFromShare] Loading album: \(musicId)")
                let fetchedAlbum = try await appleMusicService.fetchAlbum(id: musicId)
                self.album = fetchedAlbum
                print("✅ [AddAlbumFromShare] Album loaded: \(fetchedAlbum.title)")

            case .track:
                print("🎵 [AddAlbumFromShare] Loading track: \(musicId)")
                let fetchedTrack = try await appleMusicService.fetchTrack(id: musicId)
                self.track = fetchedTrack
                print("✅ [AddAlbumFromShare] Track loaded: \(fetchedTrack.title)")
            }
        } catch {
            print("❌ [AddAlbumFromShare] Failed to load music: \(error)")
            errorMessage = "音楽情報の取得に失敗しました"
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
            switch musicType {
            case .album:
                // アルバムの場合はリストを取得
                lists = try await supabaseService.fetchUserLists(userId: userId)
                // デフォルトで「聴いた」リストを選択
                selectedList = lists.first(where: { $0.defaultType == .listened })
                print("✅ [AddAlbumFromShare] Loaded \(lists.count) lists")

            case .track:
                // トラックの場合はユーザーアルバムを取得
                userAlbums = try await supabaseService.fetchUserAlbums(userId: userId.uuidString)
                print("✅ [AddAlbumFromShare] Loaded \(userAlbums.count) user albums")
            }
        } catch {
            print("❌ [AddAlbumFromShare] Failed to load lists/albums: \(error)")
            errorMessage = musicType == .album ? "リストの取得に失敗しました" : "アルバムの取得に失敗しました"
        }

        isLoadingLists = false
    }

    func addToSelectedDestination() async {
        isAdding = true
        errorMessage = nil

        do {
            switch musicType {
            case .album:
                guard let album = album else { return }
                guard let list = selectedList else {
                    errorMessage = "リストを選択してください"
                    isAdding = false
                    return
                }

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

            case .track:
                guard let track = track else { return }
                guard let userAlbum = selectedUserAlbum else {
                    errorMessage = "アルバムを選択してください"
                    isAdding = false
                    return
                }

                // ユーザーアルバムに曲を追加
                try await supabaseService.addTrackToUserAlbum(
                    albumId: userAlbum.id,
                    trackId: track.id,
                    title: track.title,
                    artist: track.artist,
                    albumArt: track.artworkURL
                )

                print("✅ [AddAlbumFromShare] Track added to user album: \(userAlbum.name)")
                addSuccess = true
            }

            // App Groupsから削除
            AppGroupManager.shared.removePendingAlbum(albumId: musicId)

        } catch {
            print("❌ [AddAlbumFromShare] Failed to add music: \(error)")
            errorMessage = "追加に失敗しました"
        }

        isAdding = false
    }
}
