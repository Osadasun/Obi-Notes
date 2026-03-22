//
//  DetailedReviewCard.swift
//  Obi
//
//  詳細レビューカード（共通コンポーネント）
//

import SwiftUI

struct DetailedReviewCard: View {
    let reviewWithUser: ReviewWithUser

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ユーザー情報
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(reviewWithUser.user.displayName.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.purple)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(reviewWithUser.user.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(reviewWithUser.review.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 評価
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(reviewWithUser.review.rating) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }

            // レビュー本文
            if let reviewText = reviewWithUser.review.text, !reviewText.isEmpty {
                Text(reviewText)
                    .font(.body)
                    .lineLimit(5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
