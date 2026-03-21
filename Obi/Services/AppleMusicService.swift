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
        print("🎵 Requesting MusicKit authorization...")
        let status = await MusicAuthorization.request()
        print("🎵 Authorization status: \(status)")

        // 追加情報をログ
        switch status {
        case .authorized:
            print("✅ MusicKit authorized successfully")
        case .denied:
            print("❌ MusicKit authorization denied")
        case .notDetermined:
            print("⚠️ MusicKit authorization not determined")
        case .restricted:
            print("🚫 MusicKit authorization restricted")
        @unknown default:
            print("❓ Unknown MusicKit authorization status")
        }

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

        // デバッグ用ログ
        print("🔍 Searching for: \(query)")
        print("🔑 Authorization status: \(MusicAuthorization.currentStatus)")

        let response: MusicCatalogSearchResponse
        do {
            response = try await request.response()
            print("✅ Search successful, albums: \(response.albums.count), songs: \(response.songs.count)")
        } catch {
            print("❌ Search failed with error: \(error)")
            print("❌ Error localizedDescription: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ NSError domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ NSError userInfo: \(nsError.userInfo)")
            }
            throw error
        }

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

    // MARK: - Popular Albums

    func fetchPopularAlbums(limit: Int = 9) async throws -> [Album] {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        // 人気の検索キーワードを使用してアルバムを取得
        // 複数のジャンルや人気アーティストで検索して多様性を確保
        let searchTerms = ["top hits 2024", "new releases", "popular music"]
        var allAlbums: [Album] = []

        for term in searchTerms {
            var request = MusicCatalogSearchRequest(term: term, types: [MusicKit.Album.self])
            request.limit = limit / searchTerms.count + 1

            do {
                let response = try await request.response()
                let albums = response.albums.map { musicKitAlbum in
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
                allAlbums.append(contentsOf: albums)
            } catch {
                print("⚠️ 検索エラー (\(term)): \(error)")
            }
        }

        // 重複を削除してlimitまで返す
        var uniqueAlbums: [Album] = []
        var seenIds = Set<String>()

        for album in allAlbums {
            if !seenIds.contains(album.id) {
                uniqueAlbums.append(album)
                seenIds.insert(album.id)
                if uniqueAlbums.count >= limit {
                    break
                }
            }
        }

        print("✅ 人気アルバム取得成功: \(uniqueAlbums.count)件")
        return uniqueAlbums
    }

    // MARK: - Fetch Details

    func fetchAlbum(id: String) async throws -> Album {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        let musicItemID = MusicItemID(id)

        let request = MusicCatalogResourceRequest<MusicKit.Album>(matching: \.id, equalTo: musicItemID)

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

        let musicItemID = MusicItemID(id)

        let request = MusicCatalogResourceRequest<MusicKit.Song>(matching: \.id, equalTo: musicItemID)

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

    // MARK: - Album Tracks

    func fetchAlbumTracks(albumId: String) async throws -> [Track] {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        let musicItemID = MusicItemID(albumId)

        var request = MusicCatalogResourceRequest<MusicKit.Album>(matching: \.id, equalTo: musicItemID)
        request.properties = [.tracks]

        let response = try await request.response()

        guard let musicKitAlbum = response.items.first else {
            throw MusicError.notFound
        }

        guard let tracks = musicKitAlbum.tracks else {
            return []
        }

        return tracks.map { musicKitSong in
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
