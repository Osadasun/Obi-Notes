//
//  ReviewCard.swift
//  Obi
//
//  共通レビューカードコンポーネント
//

import SwiftUI

// MARK: - Review Card
struct ReviewCard: View {
    let review: Review
    let showUsername: Bool
    let username: String?

    init(review: Review, showUsername: Bool = false, username: String? = nil) {
        self.review = review
        self.showUsername = showUsername
        self.username = username
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左側：アルバム画像 + 評価
            VStack(spacing: 8) {
                // アートワーク
                if let artworkURL = review.albumArt, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }

                // 評価
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.2f", review.rating))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            // 右側：レビューテキスト
            VStack(alignment: .leading, spacing: 4) {
                if let reviewText = review.text, !reviewText.isEmpty {
                    Text(reviewText)
                        .font(.body)
                        .lineLimit(3)
                }

                if showUsername, let username = username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Review Card with User
extension ReviewCard {
    init(reviewWithUser: ReviewWithUser) {
        self.review = reviewWithUser.review
        self.showUsername = true
        self.username = reviewWithUser.user.displayName
    }
}
