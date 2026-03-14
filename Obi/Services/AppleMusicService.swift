//
//  AppleMusicService.swift
//  Obi
//
//  Apple Music API連携サービス
//

import Foundation
import MusicKit

class AppleMusicService {
    static let shared = AppleMusicService()

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        return status == .authorized
    }

    var isAuthorized: Bool {
        MusicAuthorization.currentStatus == .authorized
    }

    // MARK: - Search

    func searchMusic(query: String) async throws -> MusicSearchResult {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Album.self, MusicKit.Song.self])
        request.limit = 25

        let response = try await request.response()

        // アルバムを変換
        let albums = response.albums.map { musicKitAlbum -> Album in
            Album(
                id: musicKitAlbum.id.rawValue,
                title: musicKitAlbum.title,
                artist: musicKitAlbum.artistName,
                artworkURL: musicKitAlbum.artwork?.url(width: 600, height: 600)?.absoluteString,
                releaseDate: musicKitAlbum.releaseDate,
                genre: musicKitAlbum.genreNames.first,
                trackCount: musicKitAlbum.trackCount
            )
        }

        // 楽曲を変換
        let tracks = response.songs.map { musicKitSong -> Track in
            Track(
                id: musicKitSong.id.rawValue,
                title: musicKitSong.title,
                artist: musicKitSong.artistName,
                albumTitle: musicKitSong.albumTitle,
                artworkURL: musicKitSong.artwork?.url(width: 600, height: 600)?.absoluteString,
                duration: musicKitSong.duration.map { Int($0 * 1000) },
                trackNumber: musicKitSong.trackNumber
            )
        }

        return MusicSearchResult(albums: albums, tracks: tracks)
    }

    func searchAlbums(query: String, limit: Int = 25) async throws -> [Album] {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Album.self])
        request.limit = limit

        let response = try await request.response()

        return response.albums.map { musicKitAlbum in
            Album(
                id: musicKitAlbum.id.rawValue,
                title: musicKitAlbum.title,
                artist: musicKitAlbum.artistName,
                artworkURL: musicKitAlbum.artwork?.url(width: 600, height: 600)?.absoluteString,
                releaseDate: musicKitAlbum.releaseDate,
                genre: musicKitAlbum.genreNames.first,
                trackCount: musicKitAlbum.trackCount
            )
        }
    }

    func searchTracks(query: String, limit: Int = 25) async throws -> [Track] {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Song.self])
        request.limit = limit

        let response = try await request.response()

        return response.songs.map { musicKitSong in
            Track(
                id: musicKitSong.id.rawValue,
                title: musicKitSong.title,
                artist: musicKitSong.artistName,
                albumTitle: musicKitSong.albumTitle,
                artworkURL: musicKitSong.artwork?.url(width: 600, height: 600)?.absoluteString,
                duration: musicKitSong.duration.map { Int($0 * 1000) },
                trackNumber: musicKitSong.trackNumber
            )
        }
    }

    // MARK: - Fetch Details

    func fetchAlbum(id: String) async throws -> Album {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        guard let musicItemID = MusicItemID(id) else {
            throw MusicError.notFound
        }

        var request = MusicCatalogResourceRequest<MusicKit.Album>(matching: \.id, equalTo: musicItemID)
        request.properties = [.artistName, .artwork, .releaseDate, .genreNames, .trackCount]

        let response = try await request.response()

        guard let musicKitAlbum = response.items.first else {
            throw MusicError.notFound
        }

        return Album(
            id: musicKitAlbum.id.rawValue,
            title: musicKitAlbum.title,
            artist: musicKitAlbum.artistName,
            artworkURL: musicKitAlbum.artwork?.url(width: 600, height: 600)?.absoluteString,
            releaseDate: musicKitAlbum.releaseDate,
            genre: musicKitAlbum.genreNames.first,
            trackCount: musicKitAlbum.trackCount
        )
    }

    func fetchTrack(id: String) async throws -> Track {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        guard let musicItemID = MusicItemID(id) else {
            throw MusicError.notFound
        }

        var request = MusicCatalogResourceRequest<MusicKit.Song>(matching: \.id, equalTo: musicItemID)
        request.properties = [.artistName, .artwork, .albumTitle, .duration, .trackNumber]

        let response = try await request.response()

        guard let musicKitSong = response.items.first else {
            throw MusicError.notFound
        }

        return Track(
            id: musicKitSong.id.rawValue,
            title: musicKitSong.title,
            artist: musicKitSong.artistName,
            albumTitle: musicKitSong.albumTitle,
            artworkURL: musicKitSong.artwork?.url(width: 600, height: 600)?.absoluteString,
            duration: musicKitSong.duration.map { Int($0 * 1000) },
            trackNumber: musicKitSong.trackNumber
        )
    }
}

// MARK: - Music Error
enum MusicError: LocalizedError {
    case notAuthorized
    case notFound
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Apple Musicへのアクセスが許可されていません"
        case .notFound:
            return "音楽が見つかりませんでした"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}
