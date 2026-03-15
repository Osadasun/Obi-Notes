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

    private var searchTask: Task<Void, Never>?

    init() {
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
}
