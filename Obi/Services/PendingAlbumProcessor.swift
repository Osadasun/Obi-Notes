//
//  PendingAlbumProcessor.swift
//  Obi
//
//  Share Extensionから追加された保留中のアルバムを「聴いた」リストに追加する処理
//

import Foundation
import Combine

@MainActor
class PendingAlbumProcessor: ObservableObject {
    static let shared = PendingAlbumProcessor()

    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared
    private let appGroupManager = AppGroupManager.shared
    private let appleMusicService = AppleMusicService.shared

    private init() {}

    /// 保留中のアルバムを処理
    func processPendingAlbums() async {
        print("🔄 [PendingAlbumProcessor] processPendingAlbums() called")
        
        guard !isProcessing else {
            print("⚠️ [PendingAlbumProcessor] Already processing, skipping")
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            // 保留中のアルバムを取得
            print("📋 [PendingAlbumProcessor] Getting pending albums...")
            let pendingAlbums = appGroupManager.getPendingAlbums()

            guard !pendingAlbums.isEmpty else {
                print("📋 [PendingAlbumProcessor] 保留中のアルバムはありません")
                isProcessing = false
                return
            }

            print("📋 [PendingAlbumProcessor] 保留中のアルバム: \(pendingAlbums.count)件")
            for (index, album) in pendingAlbums.enumerated() {
                print("   [\(index)] \(album.title) - \(album.artist) (ID: \(album.albumId))")
            }

            // 現在のユーザーIDを取得（UserManagerから）
            print("👤 [PendingAlbumProcessor] Getting user ID...")
            guard let userId = UserManager.shared.currentUserId else {
                print("❌ [PendingAlbumProcessor] ユーザーが認証されていません")
                isProcessing = false
                return
            }
            print("✅ [PendingAlbumProcessor] User ID: \(userId)")

            // 「聴いた」リストを取得
            print("📝 [PendingAlbumProcessor] Getting user lists...")
            let lists = try await supabaseService.fetchUserLists(userId: userId)
            print("✅ [PendingAlbumProcessor] Found \(lists.count) lists")
            
            guard let listenedList = lists.first(where: { $0.defaultType == .listened }) else {
                print("❌ [PendingAlbumProcessor] 「聴いた」リストが見つかりません")
                print("   Available lists: \(lists.map { $0.name }.joined(separator: ", "))")
                isProcessing = false
                return
            }
            print("✅ [PendingAlbumProcessor] Found listened list: \(listenedList.name) (ID: \(listenedList.id))")

            // 既存のリストアイテムを取得（重複チェック用）
            print("📋 [PendingAlbumProcessor] Fetching existing items for duplicate check...")
            let existingItems = try await supabaseService.fetchListItems(listId: listenedList.id)
            let existingTargetIds = Set(existingItems.map { $0.targetId })
            print("   Found \(existingItems.count) existing items")

            // 各アルバムを処理
            for (index, pendingAlbum) in pendingAlbums.enumerated() {
                do {
                    print("🎵 [PendingAlbumProcessor] Processing [\(index+1)/\(pendingAlbums.count)]: \(pendingAlbum.title)")

                    // Apple Music APIから詳細情報を取得
                    print("   Fetching from Apple Music API...")
                    let album = try await appleMusicService.fetchAlbum(id: pendingAlbum.albumId)
                    print("   ✅ Got album data: \(album.title)")

                    // 重複チェック
                    if existingTargetIds.contains(album.id) {
                        print("   ⚠️ Already in list, skipping: \(album.title)")
                        appGroupManager.removePendingAlbum(albumId: pendingAlbum.albumId)
                        continue
                    }

                    // 「聴いた」リストに追加
                    print("   Adding to listened list...")
                    try await supabaseService.addToList(
                        listId: listenedList.id,
                        targetType: .album,
                        targetId: album.id,
                        title: album.title,
                        artist: album.artist,
                        artworkURL: album.artworkURL300
                    )

                    print("✅ [PendingAlbumProcessor] 「聴いた」リストに追加: \(album.title)")

                    // 保留リストから削除
                    appGroupManager.removePendingAlbum(albumId: pendingAlbum.albumId)
                    print("   ✅ Removed from pending list")
                } catch {
                    print("❌ [PendingAlbumProcessor] アルバム追加エラー (\(pendingAlbum.albumId)): \(error)")
                    // エラーが発生してもスキップして続行
                }
            }

            print("✅ [PendingAlbumProcessor] 保留中のアルバム処理完了")
        } catch {
            print("❌ [PendingAlbumProcessor] 保留中のアルバム処理エラー: \(error)")
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }
}
