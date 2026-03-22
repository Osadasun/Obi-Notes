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

    private let supabaseService = SupabaseService.shared

    init(track: Track) {
        self.track = track
    }

    // MARK: - Load Data

    func loadData() async {
        await loadReviews()
    }

    func loadReviews() async {
        guard !track.id.isEmpty else { return }

        isLoadingReviews = true
        errorMessage = nil

        do {
            // Supabaseからこの曲のレビューを取得
            let allReviews = try await supabaseService.fetchReviewsWithUsers()
            reviews = allReviews.filter { $0.review.targetId == track.id }
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
