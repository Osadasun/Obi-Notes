//
//  User.swift
//  Obi
//
//  ユーザーモデル
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var displayName: String
    var photoURL: String?
    var bio: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case photoURL = "photo_url"
        case bio
        case createdAt = "created_at"
    }
}

// MARK: - User Statistics
struct UserStats: Codable {
    let userId: UUID
    let totalReviews: Int
    let avgRating: Double
    let uniqueAlbums: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case totalReviews = "total_reviews"
        case avgRating = "avg_rating"
        case uniqueAlbums = "unique_albums"
    }
}
