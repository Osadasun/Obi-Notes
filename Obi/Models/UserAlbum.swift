//
//  UserAlbum.swift
//  Obi
//
//  ユーザーが作成したアルバムのモデル
//

import Foundation

struct UserAlbum: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let name: String
    let colorHex: String // 単色カラー（例: "#FF5733"）
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case colorHex = "color_hex"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// ObiViewで表示するための統合型
enum ObiItem: Identifiable {
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
