//
//  MockMusicService.swift
//  Obi
//
//  Apple Music APIが使えない場合のモックサービス
//

import Foundation

class MockMusicService {
    static let shared = MockMusicService()

    private init() {}

    // MARK: - Mock Data

    private let mockAlbums: [Album] = [
        Album(
            id: "1440935490",
            title: "STRAY SHEEP",
            artist: "米津玄師",
            artworkURL: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/4e/6d/e0/4e6de0c8-5c1a-3c7e-8f1f-5c5e5c5e5c5e/20UMGIM12345.rgb.jpg/600x600bb.jpg",
            releaseDate: nil,
            genre: "J-Pop",
            trackCount: 15
        ),
        Album(
            id: "1440935491",
            title: "だから僕は音楽を辞めた",
            artist: "ヨルシカ",
            artworkURL: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/4e/6d/e0/4e6de0c8-5c1a-3c7e-8f1f-5c5e5c5e5c5e/20UMGIM12345.rgb.jpg/600x600bb.jpg",
            releaseDate: nil,
            genre: "J-Pop",
            trackCount: 14
        ),
        Album(
            id: "1440935492",
            title: "盗作",
            artist: "ヨルシカ",
            artworkURL: nil,
            releaseDate: nil,
            genre: "J-Pop",
            trackCount: 10
        ),
        Album(
            id: "1440935493",
            title: "THE BOOK",
            artist: "YOASOBI",
            artworkURL: nil,
            releaseDate: nil,
            genre: "J-Pop",
            trackCount: 12
        ),
        Album(
            id: "1440935494",
            title: "Kick Back",
            artist: "米津玄師",
            artworkURL: nil,
            releaseDate: nil,
            genre: "J-Pop",
            trackCount: 1
        )
    ]

    private let mockTracks: [Track] = [
        Track(
            id: "1440935500",
            title: "夜に駆ける",
            artist: "YOASOBI",
            albumTitle: "THE BOOK",
            artworkURL: nil,
            duration: 260000,
            trackNumber: 1
        ),
        Track(
            id: "1440935501",
            title: "Lemon",
            artist: "米津玄師",
            albumTitle: "Lemon",
            artworkURL: nil,
            duration: 280000,
            trackNumber: 1
        ),
        Track(
            id: "1440935502",
            title: "春を告げる",
            artist: "ヨルシカ",
            albumTitle: "だから僕は音楽を辞めた",
            artworkURL: nil,
            duration: 245000,
            trackNumber: 5
        )
    ]

    // MARK: - Authorization (Always returns true for mock)

    func requestAuthorization() async -> Bool {
        print("🎭 Mock: Authorization requested (always returns true)")
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        return true
    }

    var isAuthorized: Bool {
        return true
    }

    // MARK: - Search

    func searchMusic(query: String) async throws -> MusicSearchResult {
        print("🎭 Mock: Searching for '\(query)'")

        // 検索をシミュレート（少し待機）
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機

        // クエリに基づいてフィルタリング
        let lowercaseQuery = query.lowercased()

        let filteredAlbums = mockAlbums.filter { album in
            album.title.lowercased().contains(lowercaseQuery) ||
            album.artist.lowercased().contains(lowercaseQuery)
        }

        let filteredTracks = mockTracks.filter { track in
            track.title.lowercased().contains(lowercaseQuery) ||
            track.artist.lowercased().contains(lowercaseQuery)
        }

        print("🎭 Mock: Found \(filteredAlbums.count) albums, \(filteredTracks.count) tracks")

        return MusicSearchResult(albums: filteredAlbums, tracks: filteredTracks)
    }

    func searchAlbums(query: String, limit: Int = 25) async throws -> [Album] {
        let result = try await searchMusic(query: query)
        return Array(result.albums.prefix(limit))
    }

    func searchTracks(query: String, limit: Int = 25) async throws -> [Track] {
        let result = try await searchMusic(query: query)
        return Array(result.tracks.prefix(limit))
    }

    // MARK: - Popular Albums

    func fetchPopularAlbums(limit: Int = 9) async throws -> [Album] {
        print("🎭 Mock: Fetching popular albums (limit: \(limit))")
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        return Array(mockAlbums.prefix(limit))
    }

    // MARK: - Fetch Details

    func fetchAlbum(id: String) async throws -> Album {
        print("🎭 Mock: Fetching album with id '\(id)'")

        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機

        if let album = mockAlbums.first(where: { $0.id == id }) {
            return album
        }

        throw MusicError.notFound
    }

    func fetchTrack(id: String) async throws -> Track {
        print("🎭 Mock: Fetching track with id '\(id)'")

        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機

        if let track = mockTracks.first(where: { $0.id == id }) {
            return track
        }

        throw MusicError.notFound
    }
}
