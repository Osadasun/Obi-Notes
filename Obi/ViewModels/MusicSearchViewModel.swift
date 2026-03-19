//
//  MusicSearchViewModel.swift
//  Obi
//
//  音楽検索のViewModel
//

import Foundation
import Combine

@MainActor
class MusicSearchViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var tracks: [Track] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var musicService: Any {
        AppConfig.useMockMusicService ? MockMusicService.shared : AppleMusicService.shared
    }

    func searchMusic(query: String) async {
        guard !query.isEmpty else {
            clearResults()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result: MusicSearchResult

            if AppConfig.useMockMusicService {
                result = try await (musicService as! MockMusicService).searchMusic(query: query)
            } else {
                result = try await (musicService as! AppleMusicService).searchMusic(query: query)
            }

            albums = result.albums
            tracks = result.tracks

            print("✅ 検索成功: アルバム\(albums.count)件、楽曲\(tracks.count)件")
        } catch {
            print("❌ 検索エラー: \(error)")
            errorMessage = error.localizedDescription
            clearResults()
        }

        isLoading = false
    }

    func clearResults() {
        albums = []
        tracks = []
    }
}
