//
//  HomeViewModel.swift
//  Obi
//
//  ホーム画面のViewModel
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var latestReviews: [ReviewWithUser] = []
    @Published var popularAlbums: [Album] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared
    private var musicService: Any {
        AppConfig.useMockMusicService ? MockMusicService.shared : AppleMusicService.shared
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            print("🔍 HomeViewModel: データ取得開始")

            // Apple Music APIの認証を確認
            await requestMusicAuthorizationIfNeeded()

            // 最新のレビューを取得
            latestReviews = try await supabaseService.fetchReviewsWithUsers(limit: 3)
            print("✅ レビュー取得成功: \(latestReviews.count)件")

            // アートワークを更新（レビューのみ）
            await updateMissingArtwork()

            // 人気アルバムをApple Music APIから取得
            if AppConfig.useMockMusicService {
                popularAlbums = try await (musicService as! MockMusicService).fetchPopularAlbums(limit: 9)
            } else {
                popularAlbums = try await (musicService as! AppleMusicService).fetchPopularAlbums(limit: 9)
            }
            print("✅ 人気アルバム取得成功: \(popularAlbums.count)件")
        } catch {
            print("❌ データ取得エラー: \(error)")
            print("❌ エラー詳細: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func requestMusicAuthorizationIfNeeded() async {
        // MockMusicServiceの場合は認証不要
        guard !AppConfig.useMockMusicService else { return }

        let service = musicService as! AppleMusicService
        let isAuthorized = await service.requestAuthorization()
        if isAuthorized {
            print("✅ Apple Music認証成功")
        } else {
            print("⚠️ Apple Music認証が拒否されました")
        }
    }

    private func updateMissingArtwork() async {
        print("🔍 アートワークURL更新チェック開始")

        for reviewWithUser in latestReviews {
            let review = reviewWithUser.review

            // アートワークURLがない、または無効な場合
            if review.albumArt == nil || review.albumArt?.isEmpty == true {
                print("⚠️ アートワークURLなし: \(review.title)")
                await fetchAndUpdateArtwork(for: review)
            }
        }
    }

    private func fetchAndUpdateArtwork(for review: Review) async {
        do {
            print("🎵 Apple Music APIでアルバム検索: \(review.title) - \(review.artist)")

            // Apple Music APIでアルバムを検索
            let searchQuery = "\(review.title) \(review.artist)"
            let albums: [Album]

            if AppConfig.useMockMusicService {
                albums = try await (musicService as! MockMusicService).searchAlbums(query: searchQuery, limit: 1)
            } else {
                albums = try await (musicService as! AppleMusicService).searchAlbums(query: searchQuery, limit: 1)
            }

            guard let firstAlbum = albums.first,
                  let artworkURL = firstAlbum.artworkURL else {
                print("⚠️ アルバムが見つかりませんでした")
                return
            }

            print("✅ アートワークURL取得成功: \(artworkURL)")

            // Supabaseのデータベースを更新
            try await supabaseService.updateReviewArtwork(
                reviewId: review.id,
                artworkURL: artworkURL
            )

            // ローカルのデータも更新
            if let index = latestReviews.firstIndex(where: { $0.review.id == review.id }) {
                var updatedReview = review
                updatedReview.albumArt = artworkURL
                latestReviews[index] = ReviewWithUser(
                    review: updatedReview,
                    user: latestReviews[index].user
                )
            }

            print("✅ アートワーク更新完了: \(review.title)")
        } catch {
            print("❌ アートワーク更新エラー: \(error)")
        }
    }

}
