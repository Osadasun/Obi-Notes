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
            guard let currentUserId = UserManager.shared.currentUserId else {
                print("❌ ProfileViewModel: ユーザーIDを取得できませんでした")
                errorMessage = "ユーザーIDを取得できませんでした"
                isLoading = false
                return
            }

            print("✅ ProfileViewModel: ユーザーID取得成功: \(currentUserId)")

            // ユーザー情報を取得
            user = try await supabaseService.fetchUser(id: currentUserId)
            print("✅ ProfileViewModel: ユーザー情報取得成功: \(user?.displayName ?? "N/A")")

            // レビューとリストを並行して取得
            async let reviewsResult = supabaseService.fetchMyReviews(userId: currentUserId, limit: 50)
            async let listsResult = supabaseService.fetchUserLists(userId: currentUserId)

            reviews = try await reviewsResult
            lists = try await listsResult

            print("✅ ProfileViewModel: レビュー数: \(reviews.count), リスト数: \(lists.count)")

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

    // MARK: - Update Profile

    func updateDisplayName(_ newName: String) async {
        guard let currentUserId = UserManager.shared.currentUserId else {
            print("❌ ProfileViewModel: ユーザーIDを取得できませんでした")
            return
        }

        guard var updatedUser = user else {
            print("❌ ProfileViewModel: ユーザー情報がありません")
            return
        }

        do {
            // ユーザー情報を更新
            updatedUser.displayName = newName
            try await supabaseService.updateUserProfile(updatedUser)

            // ローカルのユーザー情報も更新
            user = updatedUser
            UserManager.shared.updateDisplayName(newName)

            print("✅ ProfileViewModel: ユーザー名更新成功: \(newName)")
        } catch {
            print("❌ ProfileViewModel: ユーザー名更新エラー: \(error)")
            errorMessage = "ユーザー名の更新に失敗しました"
        }
    }
}
