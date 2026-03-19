//
//  MyReviewsViewModel.swift
//  Obi
//
//  自分のレビュー一覧のViewModel
//

import Foundation
import Combine

@MainActor
class MyReviewsViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared

    func loadMyReviews() async {
        isLoading = true
        errorMessage = nil

        do {
            guard let userId = UserManager.shared.currentUserId else {
                print("⚠️ ユーザーが認証されていません")
                reviews = []
                isLoading = false
                return
            }

            reviews = try await supabaseService.fetchMyReviews(userId: userId)
            print("✅ 自分のレビュー取得成功: \(reviews.count)件")
        } catch {
            print("❌ 自分のレビュー取得エラー: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
