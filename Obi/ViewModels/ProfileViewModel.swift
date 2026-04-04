//
//  ProfileViewModel.swift
//  Obi
//
//  プロフィール画面のViewModel
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var reviews: [Review] = []
    @Published var lists: [MusicList] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared

    // MARK: - Load Profile Data

    func loadProfileData() async {
        isLoading = true
        errorMessage = nil

        do {
            // 現在のユーザーIDを取得
            guard let currentUserId = await supabaseService.currentUserId else {
                errorMessage = "ユーザーIDを取得できませんでした"
                isLoading = false
                return
            }

            // ユーザー情報を取得
            user = try await supabaseService.fetchUser(id: currentUserId)

            // レビューとリストを並行して取得
            async let reviewsResult = supabaseService.fetchMyReviews(userId: currentUserId, limit: 50)
            async let listsResult = supabaseService.fetchUserLists(userId: currentUserId)

            reviews = try await reviewsResult
            lists = try await listsResult

        } catch {
            print("❌ ProfileViewModel: プロフィールデータの読み込みエラー: \(error)")
            errorMessage = "データの読み込みに失敗しました"
        }

        isLoading = false
    }

    // MARK: - Computed Properties

    var reviewCount: Int {
        reviews.count
    }

    var averageRating: Double {
        guard !reviews.isEmpty else { return 0.0 }
        let sum = reviews.reduce(0.0) { $0 + $1.rating }
        return sum / Double(reviews.count)
    }

    var listCount: Int {
        lists.count
    }
}
