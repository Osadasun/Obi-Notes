//
//  SupabaseService.swift
//  Obi
//
//  Supabaseクライアントの管理
//

import Foundation
// TODO: Supabase Swift SDKを追加後、以下のコメントを外してください
// import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    // TODO: Supabase Swift SDKを追加後、以下のコメントを外してください
    // let client: SupabaseClient

    private init() {
        // TODO: Supabase Swift SDKを追加後、以下のコメントを外してください
        /*
        guard SupabaseConfig.isConfigured else {
            fatalError("Supabase is not configured. Please set URL and API key in SupabaseConfig.swift")
        }

        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
        */
    }

    // MARK: - Authentication

    func signInWithApple() async throws {
        // TODO: Apple Sign In実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func signInWithGoogle() async throws {
        // TODO: Google Sign In実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func signOut() async throws {
        // TODO: Sign out実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    // MARK: - User Profile

    func fetchUser(id: UUID) async throws -> User {
        // TODO: ユーザー情報取得実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func updateUserProfile(_ user: User) async throws {
        // TODO: プロフィール更新実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    // MARK: - Reviews

    func fetchReviews(limit: Int = 20, offset: Int = 0) async throws -> [Review] {
        // TODO: レビュー取得実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func fetchReviewsWithUsers(limit: Int = 20, offset: Int = 0) async throws -> [ReviewWithUser] {
        // TODO: ユーザー情報付きレビュー取得実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func createReview(_ review: Review) async throws -> Review {
        // TODO: レビュー作成実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func updateReview(_ review: Review) async throws {
        // TODO: レビュー更新実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func deleteReview(id: UUID) async throws {
        // TODO: レビュー削除実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    // MARK: - Lists

    func fetchUserLists(userId: UUID) async throws -> [MusicList] {
        // TODO: ユーザーのリスト取得実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func createList(_ list: MusicList) async throws -> MusicList {
        // TODO: リスト作成実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func addItemToList(listId: UUID, item: ListItem) async throws {
        // TODO: リストにアイテム追加実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func removeItemFromList(itemId: UUID) async throws {
        // TODO: リストからアイテム削除実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    // MARK: - Statistics

    func fetchAlbumStats(targetId: String) async throws -> AlbumStats {
        // TODO: アルバム統計取得実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }

    func fetchUserStats(userId: UUID) async throws -> UserStats {
        // TODO: ユーザー統計取得実装
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }
}
