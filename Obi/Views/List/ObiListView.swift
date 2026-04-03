//
//  ObiListView.swift
//  Obi
//
//  全レビュー表示（Masonry風レイアウト）
//

import SwiftUI

struct ObiListView: View {
    @StateObject private var viewModel = ObiListDetailViewModel()
    var onNavigateToReview: ((Review) -> Void)? = nil

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.reviews.isEmpty {
                ContentUnavailableView(
                    "レビューがありません",
                    systemImage: "music.note",
                    description: Text("レビューを書いてみましょう")
                )
                .padding(.vertical, 40)
            } else {
                MasonryLayout(spacing: 16) {
                    ForEach(viewModel.reviews) { review in
                        Button(action: {
                            onNavigateToReview?(review)
                        }) {
                            ObiCard(
                                artworkURL: review.albumArt,
                                reviewTitle: review.reviewTitle ?? review.title,
                                reviewText: review.text ?? "レビューテキストがありません",
                                cardHeight: 240,
                                style: ObiCardStyle.forTargetType(review.targetType),
                                rating: review.rating,
                                useFlexibleWidth: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Color.clear
                    .frame(height: 120)
            }
        }
        .task {
            await viewModel.loadReviews()
        }
        .refreshable {
            await viewModel.loadReviews()
        }
    }

}

#Preview {
    NavigationStack {
        ObiListView()
    }
}
