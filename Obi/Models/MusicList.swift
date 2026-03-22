//
//  MusicList.swift
//  Obi
//
//  リストモデル
//

import Foundation

struct MusicList: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String?
    var isPublic: Bool
    let type: ListType
    let defaultType: DefaultListType?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case isPublic = "is_public"
        case type
        case defaultType = "default_type"
        case createdAt = "created_at"
    }
}

// MARK: - List Type
enum ListType: String, Codable {
    case `default`
    case custom
}

// MARK: - Default List Type
enum DefaultListType: String, Codable {
    case reviewed  // レビュー済み
    case listened  // 聴いた
    case wishlist  // 聴きたい
    case favorite  // お気に入り
}

// MARK: - List Item
struct ListItem: Identifiable, Codable {
    let id: UUID
    let listId: UUID
    let targetType: TargetType
    let targetId: String
    let addedAt: Date

    // キャッシュ
    var albumArt: String?
    var title: String
    var artist: String
    var userRating: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case listId = "list_id"
        case targetType = "target_type"
        case targetId = "target_id"
        case addedAt = "added_at"
        case albumArt = "album_art"
        case title
        case artist
        case userRating = "user_rating"
    }
}

// MARK: - List with Items
struct ListWithItems: Identifiable {
    let list: MusicList
    var items: [ListItem]

    var id: UUID { list.id }
}
