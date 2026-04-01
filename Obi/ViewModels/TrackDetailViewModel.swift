//
//  TrackDetailViewModel.swift
//  Obi
//
//  曲詳細画面のViewModel
//

import Foundation
import Combine

@MainActor
class TrackDetailViewModel: ObservableObject {
    @Published var track: Track
    @Published var reviews: [ReviewWithUser] = []
    @Published var isLoadingReviews = false
    @Published var errorMessage: String?
    @Published var hasUserReviewed = false
    @Published var isInAnyList = false

    private let supabaseService = SupabaseService.shared

    init(track: Track) {
        self.track = track
    }

    // MARK: - Load Data

    func loadData() async {
        await loadReviews()
        await checkIfInAnyList()
    }

    func checkIfInAnyList() async {
        guard let userId = UserManager.shared.currentUserId else {
            isInAnyList = false
            return
        }

        do {
            // ユーザーのすべてのユーザーアルバムを取得
            let userAlbums = try await supabaseService.fetchUserAlbums(userId: userId.uuidString)

            // 各アルバムのトラックをチェック
            for album in userAlbums {
                let tracks = try await supabaseService.fetchUserAlbumTracks(albumId: album.id)
                if tracks.contains(where: { $0.targetId == track.id }) {
                    isInAnyList = true
                    print("✅ [TrackDetail] 曲 \(track.title) はアルバム \(album.name) に追加済み")
                    return
                }
            }

            isInAnyList = false
            print("ℹ️ [TrackDetail] 曲 \(track.title) はどのアルバムにも未追加")
        } catch {
            print("❌ [TrackDetail] アルバム確認エラー: \(error)")
            isInAnyList = false
        }
    }

    func loadReviews() async {
        guard !track.id.isEmpty else { return }

        isLoadingReviews = true
        errorMessage = nil

        do {
            // この曲のレビューのみを取得（最適化済み）
            reviews = try await supabaseService.fetchReviewsForTarget(targetId: track.id)

            // ユーザーがレビュー済みかチェック
            if let userId = UserManager.shared.currentUserId {
                hasUserReviewed = reviews.contains { $0.review.userId == userId }
            } else {
                hasUserReviewed = false
            }
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
