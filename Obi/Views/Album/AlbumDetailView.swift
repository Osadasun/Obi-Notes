//
//  AlbumDetailView.swift
//  Obi
//
//  アルバム詳細画面
//

import SwiftUI

struct AlbumDetailView: View {
    @StateObject private var viewModel: AlbumDetailViewModel
    @State private var showingReviewSheet = false

    init(album: Album) {
        _viewModel = StateObject(wrappedValue: AlbumDetailViewModel(album: album))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // アルバムアート & 基本情報
                albumHeader

                // 統計情報
                if viewModel.reviewCount > 0 {
                    statsSection
                }

                // トラックリスト
                if !viewModel.tracks.isEmpty {
                    trackListSection
                }

                // レビュー一覧
                reviewsSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingReviewSheet = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $showingReviewSheet) {
            NavigationStack {
                WriteReviewView(musicItem: MusicItem(
                    id: viewModel.album.id,
                    title: viewModel.album.title,
                    artist: viewModel.album.artist,
                    artworkURL: viewModel.album.artworkURL,
                    type: .album
                ))
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Album Header

    private var albumHeader: some View {
        VStack(spacing: 16) {
            // アルバムアート
            if let artworkURL = viewModel.album.artworkURL600, let url = URL(string: artworkURL) {
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

            // アルバム情報
            VStack(spacing: 8) {
                Text(viewModel.album.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(viewModel.album.artist)
                    .font(.title3)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    if let year = viewModel.album.releaseDate?.formatted(.dateTime.year()) {
                        Text(year)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let genre = viewModel.album.genre {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(genre)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let trackCount = viewModel.album.trackCount {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(trackCount)曲")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    if let averageRating = viewModel.averageRating {
                        Text(String(format: "%.1f", averageRating))
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    Text("平均評価")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(viewModel.reviewCount)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("レビュー")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)

            Divider()
        }
    }

    // MARK: - Track List Section

    private var trackListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("トラックリスト")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 16)

            ForEach(viewModel.tracks) { track in
                TrackRow(track: track)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Reviews Section

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("レビュー")
                    .font(.headline)

                Spacer()

                if viewModel.reviewCount > 0 {
                    Text("\(viewModel.reviewCount)件")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
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
                        .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Detailed Review Card

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

#Preview {
    NavigationStack {
        AlbumDetailView(album: Album(
            id: "1",
            title: "Abbey Road",
            artist: "The Beatles",
            artworkURL: "https://example.com/artwork.jpg",
            releaseDate: Date(),
            genre: "Rock",
            trackCount: 17
        ))
    }
}
