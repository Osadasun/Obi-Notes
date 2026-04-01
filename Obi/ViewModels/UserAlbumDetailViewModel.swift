//
//  UserAlbumDetailViewModel.swift
//  Obi
//
//  ユーザーアルバム詳細画面のViewModel
//

import Foundation
import Combine

@MainActor
class UserAlbumDetailViewModel: ObservableObject {
    @Published var tracks: [ListItem] = []
    @Published var childLists: [MusicList] = []
    @Published var childUserAlbums: [UserAlbum] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let albumId: String
    private let supabaseService = SupabaseService.shared

    init(albumId: String) {
        self.albumId = albumId
    }

    func loadTracks() async {
        isLoading = true
        errorMessage = nil

        do {
            tracks = try await supabaseService.fetchUserAlbumTracks(albumId: albumId)

            // 子リストを取得（UUID形式で保存されている場合の変換が必要）
            if let parentUUID = UUID(uuidString: albumId) {
                childLists = try await supabaseService.fetchChildLists(parentListId: parentUUID)
            } else {
                childLists = []
            }

            // 子ユーザーアルバムを取得
            childUserAlbums = try await supabaseService.fetchChildUserAlbums(parentListId: albumId)

            print("✅ [UserAlbumDetail] アルバム \(albumId) のトラック取得完了: \(tracks.count)件, 子リスト: \(childLists.count)件, 子アルバム: \(childUserAlbums.count)件")
        } catch {
            print("❌ [UserAlbumDetail] トラック取得失敗: \(error)")
            errorMessage = "トラックの取得に失敗しました"
            tracks = []
        }

        isLoading = false
    }

    func addTrack(trackId: String, trackInfo: ListItem) async {
        // TODO: user_album_tracksテーブルに曲を追加する実装が必要
        print("📝 [UserAlbumDetail] トラック追加機能は未実装: \(trackId)")
    }

    func removeTrack(trackId: String) async {
        // TODO: user_album_tracksテーブルから曲を削除する実装が必要
        print("🗑️ [UserAlbumDetail] トラック削除機能は未実装: \(trackId)")
    }
}
