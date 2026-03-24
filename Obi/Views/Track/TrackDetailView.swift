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
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    // アルバムアート & 基本情報
                    trackHeader

                    // 評価表示
                    ratingSection

                    // レビュー一覧
                    reviewsSection
                }
            }

            // フローティングアクションボタン
            Button(action: {
                showingReviewSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.purple)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReviewSheet) {
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
        .sheet(isPresented: $showingAddToListSheet) {
            AddToListView(track: viewModel.track)
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Track Header

    private var trackHeader: some View {
        VStack(spacing: 16) {
            // アルバムアート
            if let artworkURL = viewModel.track.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 250, height: 250)
                .cornerRadius(12)
                .shadow(radius: 10)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 250, height: 250)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
            }

            // 曲情報
            VStack(spacing: 8) {
                Text(viewModel.track.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(viewModel.track.artist)
                    .font(.title3)
                    .foregroundColor(.secondary)

                if let albumTitle = viewModel.track.albumTitle {
                    Text(albumTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let duration = viewModel.track.durationFormatted {
                    Text(duration)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Rating Section

    private var ratingSection: some View {
        HStack {
            // 評価表示
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.body)
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", viewModel.averageRating ?? 0.0))
                    .font(.body)
                    .fontWeight(.semibold)
            }

            Spacer()

            // +ボタン（リストに追加）
            Button(action: {
                showingAddToListSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.body)
                    .foregroundColor(.purple)
                    .frame(width: 32, height: 32)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Circle())
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
