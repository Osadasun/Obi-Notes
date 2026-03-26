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

        // TODO: user_album_tracksテーブルから曲を取得する実装が必要
        // 現在は空の配列を返す
        tracks = []

        print("✅ [UserAlbumDetail] アルバム \(albumId) のトラック取得完了: \(tracks.count)件")

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
