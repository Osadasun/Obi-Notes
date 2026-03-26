//
//  SharedAlbumData.swift
//  Obi
//
//  Share ExtensionとメインアプリでApp Group経由で共有するデータ
//

import Foundation

/// Share Extensionから「聴いた」リストに追加するアルバム情報
struct SharedAlbumData: Codable {
    let albumId: String
    let title: String
    let artist: String
    let artworkURL: String?
    let addedAt: Date

    init(albumId: String, title: String, artist: String, artworkURL: String?) {
        self.albumId = albumId
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
        self.addedAt = Date()
    }
}

/// App Group経由で共有される保留中のアルバムリスト
struct PendingAlbumsData: Codable {
    var albums: [SharedAlbumData]

    init(albums: [SharedAlbumData] = []) {
        self.albums = albums
    }
}
