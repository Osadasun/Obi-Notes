//
//  UserAlbum.swift
//  Obi
//
//  ユーザーが作成したアルバムのモデル
//

import Foundation

struct UserAlbum: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let userId: String
    let name: String
    let artistName: String // アーティスト名（ユーザー名）
    let colorHex: String // 単色カラー（例: "#FF5733"）
    let createdAt: Date
    let updatedAt: Date
    var parentListId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case artistName = "artist_name"
        case colorHex = "color_hex"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case parentListId = "parent_list_id"
    }
}

// ObiViewで表示するための統合型
enum ObiItem: Identifiable, Hashable {
    case list(MusicList, latestActivityDate: Date)
    case userAlbum(UserAlbum, latestActivityDate: Date)

    var id: String {
        switch self {
        case .list(let list, _):
            return "list-\(list.id)"
        case .userAlbum(let album, _):
            return "album-\(album.id)"
        }
    }

    var name: String {
        switch self {
        case .list(let list, _):
            return list.name
        case .userAlbum(let album, _):
            return album.name
        }
    }

    // ソート用の最新日付（リスト作成日 vs 最新アイテム追加日、アルバム更新日 vs 最新トラック追加日）
    var latestDate: Date {
        switch self {
        case .list(_, let latestActivityDate):
            return latestActivityDate
        case .userAlbum(_, let latestActivityDate):
            return latestActivityDate
        }
    }
}
