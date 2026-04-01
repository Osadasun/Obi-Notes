//
//  TrackDetailView.swift
//  Obi
//
//  曲詳細画面
//

import SwiftUI

struct TrackDetailView: View {
    @StateObject private var viewModel: TrackDetailViewModel
    @State private var showingReviewSheet = false
    @State private var showingAddToListSheet = false

    init(track: Track) {
        _viewModel = StateObject(wrappedValue: TrackDetailViewModel(track: track))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // アルバムアート & 基本情報
                trackHeader

                // 評価表示
                ratingSection

                // レビュー一覧
                reviewsSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReviewSheet, onDismiss: {
            Task {
                await viewModel.loadReviews()
            }
        }) {
            NavigationStack {
                WriteReviewView(musicItem: MusicItem(
                    id: viewModel.track.id,
                    title: viewModel.track.title,
                    artist: viewModel.track.artist,
                    artworkURL: viewModel.track.artworkURL,
                    type: .track
                ))
            }
        }
        .sheet(isPresented: $showingAddToListSheet, onDismiss: {
            Task {
                await viewModel.checkIfInAnyList()
            }
        }) {
            AddToListView(track: viewModel.track)
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Track Header

    private var trackHeader: some View {
        VStack(spacing: 16) {
            // CD型アートワーク
            DonutArtwork(imageUrl: viewModel.track.artworkURL, size: 250)
                .shadow(radius: 10)

            // 曲情報
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.track.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)

                Text(viewModel.track.artist)
                    .font(.title3)
                    .foregroundColor(.secondary)

                // その他の情報（アルバム・時間を・で区切る）
                let otherInfo = [viewModel.track.albumTitle, viewModel.track.durationFormatted]
                    .compactMap { $0 }
                    .joined(separator: " • ")

                if !otherInfo.isEmpty {
                    Text(otherInfo)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Rating Section

    private var ratingSection: some View {
        HStack {
            // 評価表示
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", viewModel.averageRating ?? 0.0))
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()

            // ボタン群
            HStack(spacing: 12) {
                // レビューボタン
                Button(action: {
                    showingReviewSheet = true
                }) {
                    Image(systemName: viewModel.hasUserReviewed ? "pencil.and.list.clipboard" : "square.and.pencil")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black)
                        .clipShape(Circle())
                }

                // +ボタン（リストに追加）
                Button(action: {
                    showingAddToListSheet = true
                }) {
                    Image(systemName: viewModel.isInAnyList ? "checkmark" : "plus")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Reviews Section

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("レビュー")
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            if viewModel.isLoadingReviews {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.reviews.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("まだレビューがありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("最初のレビューを書いてみましょう")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(viewModel.reviews) { reviewWithUser in
                    DetailedReviewCard(reviewWithUser: reviewWithUser)
                        .padding(.horizontal, 24)
                }
            }
        }
        .padding(.bottom, 24)
    }
}

#Preview {
    NavigationStack {
        TrackDetailView(track: Track(
            id: "1",
            title: "Come Together",
            artist: "The Beatles",
            albumTitle: "Abbey Road",
            artworkURL: "https://example.com/artwork.jpg",
            duration: 259000,
            trackNumber: 1
        ))
    }
}
