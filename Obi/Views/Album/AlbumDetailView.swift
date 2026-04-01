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
    @State private var showingAddToListSheet = false
    var onNavigateToTrack: ((Track) -> Void)? = nil

    init(album: Album, onNavigateToTrack: ((Track) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: AlbumDetailViewModel(album: album))
        self.onNavigateToTrack = onNavigateToTrack
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // アルバムアート & 基本情報
                albumHeader

                // 評価表示
                ratingSection

                // トラックリスト
                if !viewModel.tracks.isEmpty {
                    trackListSection
                }

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
                    id: viewModel.album.id,
                    title: viewModel.album.title,
                    artist: viewModel.album.artist,
                    artworkURL: viewModel.album.artworkURL,
                    type: .album
                ))
            }
        }
        .sheet(isPresented: $showingAddToListSheet, onDismiss: {
            Task {
                await viewModel.checkIfInAnyList()
            }
        }) {
            AddToListView(album: viewModel.album)
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
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.album.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)

                Text(viewModel.album.artist)
                    .font(.title3)
                    .foregroundColor(.secondary)

                if let genre = viewModel.album.genre {
                    Text(genre)
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

    // MARK: - Track List Section

    private var trackListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.tracks) { track in
                Button(action: {
                    onNavigateToTrack?(track)
                }) {
                    HStack(spacing: 12) {
                        // トラック番号
                        if let trackNumber = track.trackNumber {
                            Text("\(trackNumber)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if let duration = track.durationFormatted {
                                Text(duration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // 評価表示
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
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
