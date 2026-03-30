//
//  SearchViewModel.swift
//  Obi
//
//  音楽検索のViewModel
//

import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var albums: [Album] = []
    @Published var tracks: [Track] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthorized = false
    @Published var addedAlbumIds: Set<String> = []
    @Published var addedTrackIds: Set<String> = []

    private var searchTask: Task<Void, Never>?
    private let listId: UUID?
    private let userAlbumId: String?

    init(listId: UUID? = nil, userAlbumId: String? = nil) {
        self.listId = listId
        self.userAlbumId = userAlbumId

        if AppConfig.useMockMusicService {
            isAuthorized = MockMusicService.shared.isAuthorized
            print("🎭 Using Mock Music Service")
        } else {
            isAuthorized = AppleMusicService.shared.isAuthorized
            print("🎵 Using Apple Music Service")
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        if AppConfig.useMockMusicService {
            isAuthorized = await MockMusicService.shared.requestAuthorization()
        } else {
            isAuthorized = await AppleMusicService.shared.requestAuthorization()
        }
    }

    // MARK: - Search

    func search() {
        print("🎯 Search function called with text: '\(searchText)'")

        // 既存の検索をキャンセル
        searchTask?.cancel()

        guard !searchText.isEmpty else {
            print("⚠️ Search text is empty, returning")
            albums = []
            tracks = []
            return
        }

        print("✅ Starting search task...")
        searchTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                print("📞 Calling music service searchMusic...")
                let result: MusicSearchResult
                if AppConfig.useMockMusicService {
                    result = try await MockMusicService.shared.searchMusic(query: searchText)
                } else {
                    result = try await AppleMusicService.shared.searchMusic(query: searchText)
                }

                // Taskがキャンセルされていないか確認
                if !Task.isCancelled {
                    albums = result.albums
                    tracks = result.tracks
                }
            } catch {
                if !Task.isCancelled {
                    print("❌ Search error: \(error)")
                    print("❌ Error description: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                }
            }

            isLoading = false
        }
    }

    func searchAlbumsOnly() {
        searchTask?.cancel()

        guard !searchText.isEmpty else {
            albums = []
            return
        }

        searchTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                let result: [Album]
                if AppConfig.useMockMusicService {
                    result = try await MockMusicService.shared.searchAlbums(query: searchText)
                } else {
                    result = try await AppleMusicService.shared.searchAlbums(query: searchText)
                }

                if !Task.isCancelled {
                    albums = result
                    tracks = []
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }

            isLoading = false
        }
    }

    func searchTracksOnly() {
        searchTask?.cancel()

        guard !searchText.isEmpty else {
            tracks = []
            return
        }

        searchTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                let result: [Track]
                if AppConfig.useMockMusicService {
                    result = try await MockMusicService.shared.searchTracks(query: searchText)
                } else {
                    result = try await AppleMusicService.shared.searchTracks(query: searchText)
                }

                if !Task.isCancelled {
                    tracks = result
                    albums = []
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }

            isLoading = false
        }
    }

    // MARK: - Clear

    func clear() {
        searchTask?.cancel()
        searchText = ""
        albums = []
        tracks = []
        errorMessage = nil
    }

    // MARK: - Add/Remove Items

    func toggleAlbum(_ album: Album) async {
        if addedAlbumIds.contains(album.id) {
            // すでに追加済み - 削除する
            addedAlbumIds.remove(album.id)
            // TODO: Supabaseから削除する処理を追加
        } else {
            // 未追加 - 追加する
            addedAlbumIds.insert(album.id)

            guard let listId = listId else {
                print("❌ [SearchViewModel] listId is nil")
                return
            }

            do {
                // リストにアルバムを追加
                try await SupabaseService.shared.addToList(
                    listId: listId,
                    targetType: .album,
                    targetId: album.id,
                    title: album.title,
                    artist: album.artist,
                    artworkURL: album.artworkURL300
                )
                print("✅ [SearchViewModel] Album added to list: \(album.title)")
            } catch {
                print("❌ [SearchViewModel] Failed to add album: \(error)")
                // エラーの場合は追加状態を元に戻す
                addedAlbumIds.remove(album.id)
            }
        }
    }

    func toggleTrack(_ track: Track) async {
        if addedTrackIds.contains(track.id) {
            // すでに追加済み - 削除する
            addedTrackIds.remove(track.id)
            // TODO: Supabaseから削除する処理を追加
        } else {
            // 未追加 - 追加する
            addedTrackIds.insert(track.id)

            guard let userAlbumId = userAlbumId else {
                print("❌ [SearchViewModel] userAlbumId is nil")
                return
            }

            do {
                // ユーザーアルバムにトラックを追加
                try await SupabaseService.shared.addTrackToUserAlbum(
                    albumId: userAlbumId,
                    trackId: track.id,
                    title: track.title,
                    artist: track.artist,
                    albumArt: track.artworkURL
                )
                print("✅ [SearchViewModel] Track added to user album: \(track.title)")
            } catch {
                print("❌ [SearchViewModel] Failed to add track: \(error)")
                // エラーの場合は追加状態を元に戻す
                addedTrackIds.remove(track.id)
            }
        }
    }

    func isAlbumAdded(_ albumId: String) -> Bool {
        return addedAlbumIds.contains(albumId)
    }

    func isTrackAdded(_ trackId: String) -> Bool {
        return addedTrackIds.contains(trackId)
    }
}
