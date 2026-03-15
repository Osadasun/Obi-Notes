//
//  Review.swift
//  Obi
//
//  レビューモデル
//

import Foundation

struct Review: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let targetType: TargetType
    let targetId: String // Apple Music ID
    var rating: Double // 0.5 ~ 5.0
    var text: String?
    var isPublic: Bool
    let createdAt: Date
    var updatedAt: Date

    // Apple Music データのキャッシュ
    var albumArt: String?
    var title: String
    var artist: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case targetType = "target_type"
        case targetId = "target_id"
        case rating
        case text = "review_text"
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case albumArt = "target_artwork_url"
        case title = "target_title"
        case artist = "target_artist"
    }
}

// MARK: - Target Type
enum TargetType: String, Codable {
    case album
    case track
}

// MARK: - Review with User Info
struct ReviewWithUser: Identifiable {
    let review: Review
    let user: User

    var id: UUID { review.id }
}

// MARK: - Album Statistics
struct AlbumStats: Codable {
    let targetId: String
    let targetType: String
    let title: String
    let artist: String
    let albumArt: String?
    let avgRating: Double
    let reviewCount: Int

    enum CodingKeys: String, CodingKey {
        case targetId = "target_id"
        case targetType = "target_type"
        case title
        case artist
        case albumArt = "album_art"
        case avgRating = "average_rating"
        case reviewCount = "review_count"
    }
}
