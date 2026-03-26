//
//  MusicURLParser.swift
//  ShareExtension
//
//  Spotify/Apple Music URLを解析してアルバム情報を取得
//

import Foundation

enum MusicService {
    case appleMusic
    case spotify
    case unknown
}

struct ParsedMusicURL {
    let service: MusicService
    let albumId: String?
    let trackId: String?
    let isAlbum: Bool

    var targetId: String? {
        isAlbum ? albumId : trackId
    }
}

class MusicURLParser {

    /// URLから音楽サービスとIDを解析
    static func parse(url: URL) -> ParsedMusicURL? {
        let urlString = url.absoluteString

        // Apple Music URLのパターン
        // https://music.apple.com/jp/album/album-name/1234567890
        // https://music.apple.com/jp/album/album-name/1234567890?i=9876543210
        if urlString.contains("music.apple.com") {
            return parseAppleMusicURL(url: url)
        }

        // Spotify URLのパターン
        // https://open.spotify.com/album/3a0UOgDWw2pTajw85QPMiz
        // https://open.spotify.com/track/11dFghVXANMlKmJXsNCbNl
        if urlString.contains("open.spotify.com") {
            return parseSpotifyURL(url: url)
        }

        return nil
    }

    private static func parseAppleMusicURL(url: URL) -> ParsedMusicURL? {
        let urlString = url.absoluteString

        // クエリパラメータでトラックIDがあるかチェック
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let trackIdParam = queryItems.first(where: { $0.name == "i" }),
           let trackId = trackIdParam.value {
            // トラック指定がある場合
            // アルバムIDも抽出
            if let albumId = extractAppleMusicId(from: urlString, type: "album") {
                return ParsedMusicURL(
                    service: .appleMusic,
                    albumId: albumId,
                    trackId: trackId,
                    isAlbum: false
                )
            }
        }

        // アルバムのみの場合
        if let albumId = extractAppleMusicId(from: urlString, type: "album") {
            return ParsedMusicURL(
                service: .appleMusic,
                albumId: albumId,
                trackId: nil,
                isAlbum: true
            )
        }

        return nil
    }

    private static func extractAppleMusicId(from urlString: String, type: String) -> String? {
        // /album/album-name/1234567890 のパターンからIDを抽出
        let pattern = "/\(type)/[^/]+/(\\d+)"

        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)),
           let range = Range(match.range(at: 1), in: urlString) {
            return String(urlString[range])
        }

        return nil
    }

    private static func parseSpotifyURL(url: URL) -> ParsedMusicURL? {
        let pathComponents = url.pathComponents

        // pathComponentsは ["", "album", "3a0UOgDWw2pTajw85QPMiz"] のような形式
        guard pathComponents.count >= 3 else { return nil }

        let type = pathComponents[1] // "album" or "track"
        let id = pathComponents[2]

        switch type {
        case "album":
            return ParsedMusicURL(
                service: .spotify,
                albumId: id,
                trackId: nil,
                isAlbum: true
            )
        case "track":
            return ParsedMusicURL(
                service: .spotify,
                albumId: nil,
                trackId: id,
                isAlbum: false
            )
        default:
            return nil
        }
    }
}
