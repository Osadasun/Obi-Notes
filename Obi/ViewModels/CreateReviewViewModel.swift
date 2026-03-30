//
//  CreateReviewViewModel.swift
//  Obi
//
//  レビュー作成のViewModel
//

import Foundation
import Combine

@MainActor
class CreateReviewViewModel: ObservableObject {
    @Published var rating: Double = 3.0
    @Published var reviewTitle: String = ""
    @Published var reviewText: String = ""
    @Published var isPublic: Bool = true
    @Published var isSubmitting: Bool = false
    @Published var isSubmitted: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var musicItem: MusicItem

    private let supabaseService = SupabaseService.shared

    init(musicItem: MusicItem) {
        self.musicItem = musicItem
    }

    func updateMusicItem(_ newItem: MusicItem) {
        self.musicItem = newItem
    }

    var canSubmit: Bool {
        !reviewTitle.isEmpty && !reviewText.isEmpty && rating > 0
    }

    func submitReview() async {
        guard canSubmit else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            // 現在のユーザーIDを取得
            guard let userId = UserManager.shared.currentUserId else {
                errorMessage = "ユーザーが認証されていません"
                showError = true
                isSubmitting = false
                return
            }

            let now = Date()
            let review = Review(
                id: UUID(),
                userId: userId,
                targetType: musicItem.type == .album ? .album : .track,
                targetId: musicItem.id,
                rating: rating,
                reviewTitle: reviewTitle,
                text: reviewText,
                isPublic: isPublic,
                createdAt: now,
                updatedAt: now,
                albumArt: musicItem.artworkURL,
                title: musicItem.title,
                artist: musicItem.artist
            )

            try await supabaseService.createReview(review)

            print("✅ レビュー投稿成功")
            isSubmitted = true
        } catch {
            print("❌ レビュー投稿エラー: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }

        isSubmitting = false
    }
}
