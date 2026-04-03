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
    @Published var sortedLists: [MusicList] = [] // ピン留めとアクティビティ順でソート
    @Published var userAlbums: [UserAlbum] = []
    @Published var sortedUserAlbums: [UserAlbum] = [] // ピン留めとアクティビティ順でソート
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
    private var listLatestDates: [UUID: Date] = [:]
    private var albumLatestDates: [String: Date] = [:]
    var obiListViewModel: ObiListViewModel? = nil

    init(musicId: String, musicType: MusicTargetType, obiListViewModel: ObiListViewModel? = nil) {
        self.musicId = musicId
        self.musicType = musicType
        self.obiListViewModel = obiListViewModel
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

                // デフォルトで「聴いた」リストを選択
                selectedList = lists.first(where: { $0.defaultType == .listened })
                print("✅ [AddAlbumFromShare] Loaded \(lists.count) lists")

            case .track:
                // トラックの場合はユーザーアルバムを取得
                userAlbums = try await supabaseService.fetchUserAlbums(userId: userId.uuidString)

                // 各アルバムの最新アクティビティ日付を計算
                var latestDates: [String: Date] = [:]
                for album in userAlbums {
                    let tracks = try await supabaseService.fetchUserAlbumTracks(albumId: album.id)
                    let latestTrackDate = tracks.map { $0.addedAt }.max()
                    let latestActivityDate = max(album.updatedAt, latestTrackDate ?? album.updatedAt)
                    latestDates[album.id] = latestActivityDate
                }
                albumLatestDates = latestDates

                // ソート実行
                sortUserAlbums()

                print("✅ [AddAlbumFromShare] Loaded \(userAlbums.count) user albums")
            }
        } catch {
            print("❌ [AddAlbumFromShare] Failed to load lists/albums: \(error)")
            errorMessage = musicType == .album ? "リストの取得に失敗しました" : "アルバムの取得に失敗しました"
        }

        isLoadingLists = false
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

    // MARK: - Sort User Albums

    private func sortUserAlbums() {
        guard let obiListViewModel = obiListViewModel else {
            // obiListViewModelがない場合は最新日付順のみ
            sortedUserAlbums = userAlbums.sorted { album1, album2 in
                let date1 = albumLatestDates[album1.id] ?? album1.updatedAt
                let date2 = albumLatestDates[album2.id] ?? album2.updatedAt
                return date1 > date2
            }
            return
        }

        // ピン留めとアクティビティ日付を考慮してソート
        sortedUserAlbums = userAlbums.sorted { album1, album2 in
            let itemId1 = "album-\(album1.id)"
            let itemId2 = "album-\(album2.id)"
            let isPinned1 = obiListViewModel.isPinned(itemId: itemId1)
            let isPinned2 = obiListViewModel.isPinned(itemId: itemId2)

            // ピン留めされているアルバムが優先
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
                let date1 = albumLatestDates[album1.id] ?? album1.updatedAt
                let date2 = albumLatestDates[album2.id] ?? album2.updatedAt
                return date1 > date2
            }
        }
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
