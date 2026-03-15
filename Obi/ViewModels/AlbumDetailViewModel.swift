//
//  AlbumDetailViewModel.swift
//  Obi
//
//  アルバム詳細画面のViewModel
//

import Foundation
import Combine

@MainActor
class AlbumDetailViewModel: ObservableObject {
    @Published var album: Album
    @Published var tracks: [Track] = []
    @Published var reviews: [ReviewWithUser] = []
    @Published var isLoadingTracks = false
    @Published var isLoadingReviews = false
    @Published var errorMessage: String?

    private let musicService = AppleMusicService.shared
    private let supabaseService = SupabaseService.shared

    init(album: Album) {
        self.album = album
    }

    // MARK: - Load Data

    func loadData() async {
        await loadTracks()
        await loadReviews()
    }

    func loadTracks() async {
        guard !album.id.isEmpty else { return }

        isLoadingTracks = true
        errorMessage = nil

        // アルバムの詳細を取得してトラック情報を含める
        // 注: MusicKitのAlbumにはtracksプロパティがあるが、
        // 現在のAppleMusicServiceでは対応していないため、
        // ここでは空配列のまま（後で実装）
        tracks = []

        isLoadingTracks = false
    }

    func loadReviews() async {
        guard !album.id.isEmpty else { return }

        isLoadingReviews = true
        errorMessage = nil

        do {
            // Supabaseからこのアルバムのレビューを取得
            // 注: 現在のSupabaseServiceにはアルバムIDでフィルタする機能がないため、
            // 全レビューを取得してフィルタ（後で最適化）
            let allReviews = try await supabaseService.fetchReviewsWithUsers()
            reviews = allReviews.filter { $0.review.targetId == album.id }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingReviews = false
    }

    // MARK: - Stats

    var averageRating: Double? {
        guard !reviews.isEmpty else { return nil }
        let sum = reviews.reduce(0.0) { $0 + $1.review.rating }
        return sum / Double(reviews.count)
    }

    var reviewCount: Int {
        reviews.count
    }
}
