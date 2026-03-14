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

        // TODO: Apple Music API検索実装
        // MusicKit APIを使用してアルバムと楽曲を検索

        // 仮実装
        return MusicSearchResult(albums: [], tracks: [])
    }

    func searchAlbums(query: String, limit: Int = 25) async throws -> [Album] {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        // TODO: アルバム検索実装
        return []
    }

    func searchTracks(query: String, limit: Int = 25) async throws -> [Track] {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        // TODO: 楽曲検索実装
        return []
    }

    // MARK: - Fetch Details

    func fetchAlbum(id: String) async throws -> Album {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        // TODO: アルバム詳細取得実装
        throw MusicError.notFound
    }

    func fetchTrack(id: String) async throws -> Track {
        guard isAuthorized else {
            throw MusicError.notAuthorized
        }

        // TODO: 楽曲詳細取得実装
        throw MusicError.notFound
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
