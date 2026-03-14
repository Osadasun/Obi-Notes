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

    private let musicService = AppleMusicService.shared
    private var searchTask: Task<Void, Never>?

    init() {
        isAuthorized = musicService.isAuthorized
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        isAuthorized = await musicService.requestAuthorization()
    }

    // MARK: - Search

    func search() {
        // 既存の検索をキャンセル
        searchTask?.cancel()

        guard !searchText.isEmpty else {
            albums = []
            tracks = []
            return
        }

        searchTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                let result = try await musicService.searchMusic(query: searchText)

                // Taskがキャンセルされていないか確認
                if !Task.isCancelled {
                    albums = result.albums
                    tracks = result.tracks
                }
            } catch {
                if !Task.isCancelled {
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
                let result = try await musicService.searchAlbums(query: searchText)

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
                let result = try await musicService.searchTracks(query: searchText)

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
