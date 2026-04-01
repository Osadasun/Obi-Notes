//
//  SupabaseService.swift
//  Obi
//
//  Supabaseクライアントの管理
//

import Foundation
import Supabase
import Auth

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

    func createUser(_ user: User) async throws -> User {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        let response: User = try await client.database
            .from("profiles")
            .insert(user)
            .select()
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

    func fetchReviewsForTarget(targetId: String) async throws -> [ReviewWithUser] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            // targetIdでフィルタしたレビューのみを取得
            let reviews: [Review] = try await client.database
                .from("reviews")
                .select()
                .eq("target_id", value: targetId)
                .eq("is_public", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value

            // ユーザー情報を取得
            var reviewsWithUsers: [ReviewWithUser] = []
            for review in reviews {
                if let user = try? await fetchUser(id: review.userId) {
                    reviewsWithUsers.append(ReviewWithUser(review: review, user: user))
                }
            }

            print("✅ [SupabaseService] targetId=\(targetId)のレビュー取得成功: \(reviewsWithUsers.count)件")
            return reviewsWithUsers
        } catch {
            print("❌ [SupabaseService] targetId=\(targetId)のレビュー取得エラー: \(error)")
            throw error
        }
    }

    func fetchMyReviews(userId: UUID, limit: Int = 50) async throws -> [Review] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            let response: [Review] = try await client.database
                .from("reviews")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            print("✅ fetchMyReviews成功: \(response.count)件")
            return response
        } catch {
            print("❌ fetchMyReviewsエラー: \(error)")
            throw error
        }
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

    func fetchUserLists(userId: UUID? = nil) async throws -> [MusicList] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        // userIdが指定されていない場合は現在のユーザーを使用
        let targetUserId: UUID
        if let userId = userId {
            targetUserId = userId
        } else if let currentUserId = UserManager.shared.currentUserId {
            targetUserId = currentUserId
        } else {
            throw SupabaseError.notConfigured
        }

        let response: [MusicList] = try await client.database
            .from("lists")
            .select()
            .eq("user_id", value: targetUserId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func fetchChildLists(parentListId: UUID) async throws -> [MusicList] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let response: [MusicList] = try await client.database
            .from("lists")
            .select()
            .eq("parent_list_id", value: parentListId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ [fetchChildLists] Found \(response.count) child lists for parent: \(parentListId)")
        return response
    }

    func createList(_ list: MusicList, parentListId: UUID? = nil) async throws -> MusicList {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        var listToInsert = list
        if let parentId = parentListId {
            listToInsert = MusicList(
                id: list.id,
                userId: list.userId,
                name: list.name,
                description: list.description,
                isPublic: list.isPublic,
                type: list.type,
                defaultType: list.defaultType,
                createdAt: list.createdAt,
                parentListId: parentId
            )
        }

        let response: MusicList = try await client.database
            .from("lists")
            .insert(listToInsert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func updateList(listId: UUID, name: String?, description: String?, isPublic: Bool?) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        struct UpdateList: Encodable {
            let name: String?
            let description: String?
            let is_public: Bool?
        }

        let updates = UpdateList(
            name: name,
            description: description,
            is_public: isPublic
        )

        try await client
            .from("lists")
            .update(updates)
            .eq("id", value: listId)
            .execute()
    }

    func createDefaultLists(for userId: UUID) async throws {
        guard client != nil else {
            throw SupabaseError.notConfigured
        }

        let defaultLists: [(DefaultListType, String)] = [
            (.reviewed, "レビュー済み"),
            (.favorite, "お気に入り"),
            (.listened, "聴いた"),
            (.wishlist, "聴きたい")
        ]

        for (type, name) in defaultLists {
            let list = MusicList(
                id: UUID(),
                userId: userId,
                name: name,
                description: nil,
                isPublic: false,
                type: .default,
                defaultType: type,
                createdAt: Date(),
                parentListId: nil
            )

            do {
                _ = try await createList(list)
                print("✅ デフォルトリスト作成成功: \(name)")
            } catch {
                print("❌ デフォルトリスト作成エラー (\(name)): \(error)")
                // エラーがあっても続行（既に存在する場合など）
            }
        }
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

    // MARK: - Add/Remove from List (Convenience Methods)

    func addToList(
        listId: UUID,
        targetType: TargetType,
        targetId: String,
        title: String,
        artist: String,
        artworkURL: String?
    ) async throws {
        guard client != nil else {
            throw SupabaseError.notConfigured
        }

        let item = ListItem(
            id: UUID(),
            listId: listId,
            targetType: targetType,
            targetId: targetId,
            addedAt: Date(),
            albumArt: artworkURL,
            title: title,
            artist: artist,
            userRating: nil
        )

        try await addItemToList(listId: listId, item: item)
    }

    func removeFromList(listId: UUID, targetId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        // まず該当するアイテムを検索
        let items: [ListItem] = try await client.database
            .from("list_items")
            .select()
            .eq("list_id", value: listId.uuidString)
            .eq("target_id", value: targetId)
            .execute()
            .value

        // 見つかったアイテムを削除
        for item in items {
            try await removeItemFromList(itemId: item.id)
        }
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

    // MARK: - User Albums

    func fetchUserAlbums(userId: String) async throws -> [UserAlbum] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        guard let userUUID = UUID(uuidString: userId) else {
            throw SupabaseError.notConfigured
        }

        let response: [UserAlbum] = try await client
            .from("user_albums")
            .select()
            .eq("user_id", value: userUUID)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    func fetchChildUserAlbums(parentListId: String) async throws -> [UserAlbum] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let response: [UserAlbum] = try await client
            .from("user_albums")
            .select()
            .eq("parent_list_id", value: parentListId)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ [fetchChildUserAlbums] Found \(response.count) child albums for parent: \(parentListId)")
        return response
    }

    func createUserAlbum(userId: String, name: String, artistName: String, colorHex: String, parentListId: String? = nil) async throws -> UserAlbum {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        struct NewAlbum: Encodable {
            let user_id: UUID
            let name: String
            let artist_name: String
            let color_hex: String
            let parent_list_id: UUID?
        }

        guard let userUUID = UUID(uuidString: userId) else {
            throw SupabaseError.notConfigured
        }

        let parentUUID: UUID? = if let parentId = parentListId {
            UUID(uuidString: parentId)
        } else {
            nil
        }

        let newAlbum = NewAlbum(
            user_id: userUUID,
            name: name,
            artist_name: artistName,
            color_hex: colorHex,
            parent_list_id: parentUUID
        )

        let response: UserAlbum = try await client
            .from("user_albums")
            .insert(newAlbum)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func deleteUserAlbum(albumId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        guard let albumUUID = UUID(uuidString: albumId) else {
            throw SupabaseError.notConfigured
        }

        try await client
            .from("user_albums")
            .delete()
            .eq("id", value: albumUUID)
            .execute()
    }

    func updateUserAlbum(albumId: String, name: String?, colorHex: String?) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        guard let albumUUID = UUID(uuidString: albumId) else {
            throw SupabaseError.notConfigured
        }

        struct UpdateAlbum: Encodable {
            let name: String?
            let color_hex: String?
        }

        let updates = UpdateAlbum(
            name: name,
            color_hex: colorHex
        )

        try await client
            .from("user_albums")
            .update(updates)
            .eq("id", value: albumUUID)
            .execute()
    }

    // MARK: - User Album Tracks

    func addTrackToUserAlbum(albumId: String, trackId: String, title: String, artist: String, albumArt: String?) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        guard let albumUUID = UUID(uuidString: albumId) else {
            throw SupabaseError.notConfigured
        }

        struct NewTrack: Encodable {
            let album_id: UUID
            let track_id: String
            let title: String
            let artist: String
            let album_art: String?
        }

        let newTrack = NewTrack(
            album_id: albumUUID,
            track_id: trackId,
            title: title,
            artist: artist,
            album_art: albumArt
        )

        try await client
            .from("user_album_tracks")
            .insert(newTrack)
            .execute()
    }

    func fetchUserAlbumTracks(albumId: String) async throws -> [ListItem] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        guard let albumUUID = UUID(uuidString: albumId) else {
            throw SupabaseError.notConfigured
        }

        struct AlbumTrack: Decodable {
            let track_id: String
            let title: String
            let artist: String
            let album_art: String?
            let created_at: Date

            func toListItem() -> ListItem {
                return ListItem(
                    id: UUID(),
                    listId: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                    targetType: .track,
                    targetId: track_id,
                    addedAt: created_at,
                    albumArt: album_art,
                    title: title,
                    artist: artist,
                    userRating: nil
                )
            }
        }

        let tracks: [AlbumTrack] = try await client
            .from("user_album_tracks")
            .select()
            .eq("album_id", value: albumUUID)
            .order("created_at", ascending: false)
            .execute()
            .value

        return tracks.map { $0.toListItem() }
    }

    func removeTrackFromUserAlbum(albumId: String, trackId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        guard let albumUUID = UUID(uuidString: albumId) else {
            throw SupabaseError.notConfigured
        }

        try await client
            .from("user_album_tracks")
            .delete()
            .eq("album_id", value: albumUUID)
            .eq("track_id", value: trackId)
            .execute()
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
