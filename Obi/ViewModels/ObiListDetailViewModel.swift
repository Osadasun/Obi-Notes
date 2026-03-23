//
//  ObiListDetailViewModel.swift
//  Obi
//
//  全レビュー表示用ViewModel
//

import Foundation
import Combine

@MainActor
class ObiListDetailViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared

    func loadReviews() async {
        isLoading = true
        errorMessage = nil

        guard let userId = UserManager.shared.currentUserId else {
            errorMessage = "ユーザーが認証されていません"
            isLoading = false
            return
        }

        do {
            reviews = try await supabaseService.fetchMyReviews(userId: userId)
            print("✅ レビュー取得成功: \(reviews.count)件")
        } catch {
            print("❌ レビュー取得エラー: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
