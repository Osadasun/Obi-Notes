//
//  Album.swift
//  Obi
//
//  アルバム・楽曲モデル（Apple Music API）
//

import Foundation

// MARK: - Album
struct Album: Identifiable, Codable, Equatable {
    let id: String // Apple Music ID
    let title: String
    let artist: String
    let artworkURL: String?
    let releaseDate: Date?
    let genre: String?
    let trackCount: Int?

    var artworkURL300: String? {
        artworkURL?.replacingOccurrences(of: "{w}x{h}", with: "300x300")
    }

    var artworkURL600: String? {
        artworkURL?.replacingOccurrences(of: "{w}x{h}", with: "600x600")
    }
}

// MARK: - Track
struct Track: Identifiable, Codable, Equatable {
    let id: String // Apple Music ID
    let title: String
    let artist: String
    let albumTitle: String?
    let artworkURL: String?
    let duration: Int? // ミリ秒
    let trackNumber: Int?
    let genre: String? // ジャンル

    var durationFormatted: String? {
        guard let duration = duration else { return nil }
        let seconds = duration / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Search Result
struct MusicSearchResult {
    let albums: [Album]
    let tracks: [Track]
}
