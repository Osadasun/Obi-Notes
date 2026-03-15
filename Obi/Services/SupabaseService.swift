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

    let client: SupabaseClient?
    var isConfigured: Bool {
        client != nil
    }

    private init() {
        if SupabaseConfig.isConfigured {
            self.client = SupabaseClient(
                supabaseURL: URL(string: SupabaseConfig.url)!,
                supabaseKey: SupabaseConfig.anonKey
            )
        } else {
            self.client = nil
            print("⚠️ Supabase is not configured. Please set URL and API key in SupabaseConfig.swift")
        }
    }

    // MARK: - Current User

    var currentUser: Supabase.User? {
        get async {
            guard let client = client else { return nil }
            return try? await client.auth.session.user
        }
    }

    var currentUserId: UUID? {
        get async {
            return await currentUser?.id
        }
    }

    // MARK: - Authentication

    func signInWithApple(idToken: String, nonce: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
    }

    func signOut() async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        try await client.auth.signOut()
    }

    // MARK: - User Profile

    func fetchUser(id: UUID) async throws -> User {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
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
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        try await client.database
            .from("profiles")
            .update(user)
            .eq("id", value: user.id.uuidString)
            .execute()
    }

    // MARK: - Reviews

    func fetchReviews(limit: Int = 20, offset: Int = 0) async throws -> [Review] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            let response: [Review] = try await client.database
                .from("reviews")
                .select()
                .eq("is_public", value: true)
                .order("created_at", ascending: false)
                .limit(limit)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
            print("✅ fetchReviews成功: \(response.count)件")
            if let first = response.first {
                print("📝 最初のレビュー: id=\(first.id), title=\(first.title), artist=\(first.artist)")
            }
            return response
        } catch {
            print("❌ fetchReviewsエラー: \(error)")
            throw error
        }
    }

    func fetchReviewsWithUsers(limit: Int = 20, offset: Int = 0) async throws -> [ReviewWithUser] {
        guard client != nil else {
            throw SupabaseError.notConfigured
        }
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
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
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
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        try await client.database
            .from("reviews")
            .update(review)
            .eq("id", value: review.id.uuidString)
            .execute()
    }

    func deleteReview(id: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        try await client.database
            .from("reviews")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func updateReviewArtwork(reviewId: UUID, artworkURL: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        struct ArtworkUpdate: Codable {
            let target_artwork_url: String
        }

        let update = ArtworkUpdate(target_artwork_url: artworkURL)

        try await client.database
            .from("reviews")
            .update(update)
            .eq("id", value: reviewId.uuidString)
            .execute()

        print("✅ アートワークURL更新成功: reviewId=\(reviewId)")
    }

    func updateAllReviewsArtwork(targetId: String, artworkURL: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        struct ArtworkUpdate: Codable {
            let target_artwork_url: String
        }

        let update = ArtworkUpdate(target_artwork_url: artworkURL)

        try await client.database
            .from("reviews")
            .update(update)
            .eq("target_id", value: targetId)
            .execute()

        print("✅ アートワークURL一括更新成功: targetId=\(targetId)")
    }

    // MARK: - Lists

    func fetchUserLists(userId: UUID) async throws -> [MusicList] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
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
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
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
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        try await client.database
            .from("list_items")
            .insert(item)
            .execute()
    }

    func removeItemFromList(itemId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        try await client.database
            .from("list_items")
            .delete()
            .eq("id", value: itemId.uuidString)
            .execute()
    }

    func fetchListItems(listId: UUID) async throws -> [ListItem] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
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
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
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

    func fetchPopularAlbums(limit: Int = 9) async throws -> [AlbumStats] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            // レビュー数が多い順に取得
            let response: [AlbumStats] = try await client.database
                .from("album_stats")
                .select()
                .order("review_count", ascending: false)
                .limit(limit)
                .execute()
                .value
            print("✅ fetchPopularAlbums成功: \(response.count)件")
            if let first = response.first {
                print("📊 最初の人気アルバム: title=\(first.title), artist=\(first.artist), reviewCount=\(first.reviewCount)")
            }
            return response
        } catch {
            print("❌ fetchPopularAlbumsエラー: \(error)")
            throw error
        }
    }

    func fetchUserStats(userId: UUID) async throws -> UserStats {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
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

// MARK: - Supabase Error
enum SupabaseError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabaseが設定されていません"
        }
    }
}
