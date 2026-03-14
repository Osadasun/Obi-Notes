//
//  SupabaseService.swift
//  Obi
//
//  Supabaseクライアントの管理
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        guard SupabaseConfig.isConfigured else {
            fatalError("Supabase is not configured. Please set URL and API key in SupabaseConfig.swift")
        }

        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    // MARK: - Current User

    var currentUser: Supabase.User? {
        return try? client.auth.session.user
    }

    var currentUserId: UUID? {
        return currentUser?.id
    }

    // MARK: - Authentication

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - User Profile

    func fetchUser(id: UUID) async throws -> User {
        let response: User = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        return response
    }

    func updateUserProfile(_ user: User) async throws {
        try await client.database
            .from("profiles")
            .update(user)
            .eq("id", value: user.id.uuidString)
            .execute()
    }

    // MARK: - Reviews

    func fetchReviews(limit: Int = 20, offset: Int = 0) async throws -> [Review] {
        let response: [Review] = try await client.database
            .from("reviews")
            .select()
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .limit(limit)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        return response
    }

    func fetchReviewsWithUsers(limit: Int = 20, offset: Int = 0) async throws -> [ReviewWithUser] {
        // Supabaseでは、JOINの代わりに2回のクエリで実装
        let reviews = try await fetchReviews(limit: limit, offset: offset)

        var reviewsWithUsers: [ReviewWithUser] = []
        for review in reviews {
            if let user = try? await fetchUser(id: review.userId) {
                reviewsWithUsers.append(ReviewWithUser(review: review, user: user))
            }
        }

        return reviewsWithUsers
    }

    func createReview(_ review: Review) async throws -> Review {
        let response: Review = try await client.database
            .from("reviews")
            .insert(review)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func updateReview(_ review: Review) async throws {
        try await client.database
            .from("reviews")
            .update(review)
            .eq("id", value: review.id.uuidString)
            .execute()
    }

    func deleteReview(id: UUID) async throws {
        try await client.database
            .from("reviews")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Lists

    func fetchUserLists(userId: UUID) async throws -> [MusicList] {
        let response: [MusicList] = try await client.database
            .from("lists")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func createList(_ list: MusicList) async throws -> MusicList {
        let response: MusicList = try await client.database
            .from("lists")
            .insert(list)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func addItemToList(listId: UUID, item: ListItem) async throws {
        try await client.database
            .from("list_items")
            .insert(item)
            .execute()
    }

    func removeItemFromList(itemId: UUID) async throws {
        try await client.database
            .from("list_items")
            .delete()
            .eq("id", value: itemId.uuidString)
            .execute()
    }

    func fetchListItems(listId: UUID) async throws -> [ListItem] {
        let response: [ListItem] = try await client.database
            .from("list_items")
            .select()
            .eq("list_id", value: listId.uuidString)
            .order("added_at", ascending: false)
            .execute()
            .value
        return response
    }

    // MARK: - Statistics

    func fetchAlbumStats(targetId: String) async throws -> AlbumStats {
        // ビューから取得
        let response: AlbumStats = try await client.database
            .from("album_stats")
            .select()
            .eq("target_id", value: targetId)
            .single()
            .execute()
            .value
        return response
    }

    func fetchUserStats(userId: UUID) async throws -> UserStats {
        // ビューから取得
        let response: UserStats = try await client.database
            .from("user_stats")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        return response
    }
}
