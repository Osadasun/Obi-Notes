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
    case list(MusicList)
    case userAlbum(UserAlbum)

    var id: String {
        switch self {
        case .list(let list):
            return "list-\(list.id)"
        case .userAlbum(let album):
            return "album-\(album.id)"
        }
    }

    var name: String {
        switch self {
        case .list(let list):
            return list.name
        case .userAlbum(let album):
            return album.name
        }
    }
}
