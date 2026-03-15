//
//  HomeView.swift
//  Obi
//
//  ホーム画面（ジャケットグリッド）
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 最新のレビューセクション
                SectionHeaderView(title: "最新のレビュー", showMore: true)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if viewModel.latestReviews.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(0..<3) { index in
                            ReviewCardPlaceholder()
                        }
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.latestReviews) { reviewWithUser in
                            ReviewCard(reviewWithUser: reviewWithUser)
                        }
                    }
                    .padding(.horizontal)
                }

                // 今週の人気アルバムセクション
                SectionHeaderView(title: "今週の人気アルバム", showMore: true)

                if viewModel.popularAlbums.isEmpty {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(0..<9) { index in
                            PopularAlbumCard(album: nil)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(viewModel.popularAlbums, id: \.id) { album in
                            PopularAlbumCard(album: album)
                        }
                    }
                    .padding(.horizontal)
                }

                // 話題のレビュアーセクション
                SectionHeaderView(title: "話題のレビュアー", showMore: true)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<5) { index in
                            ReviewerCard()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 16)
        }
        .onAppear {
            if viewModel.latestReviews.isEmpty && viewModel.popularAlbums.isEmpty {
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }

    // 3列のグリッド
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    let showMore: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            if showMore {
                Button(action: {
                    // TODO: もっと見る機能
                }) {
                    Text("もっと見る")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Review Card (レコード帯風)
struct ReviewCard: View {
    let reviewWithUser: ReviewWithUser

    var body: some View {
        NavigationLink(destination: AlbumDetailView(album: Album(
            id: reviewWithUser.review.targetId,
            title: reviewWithUser.review.title,
            artist: reviewWithUser.review.artist,
            artworkURL: reviewWithUser.review.albumArt,
            releaseDate: nil,
            genre: nil,
            trackCount: nil
        ))) {
            VStack(alignment: .leading, spacing: 8) {
                // 横長サムネイル（レビュー文表示）
                ZStack(alignment: .bottomLeading) {
                    Group {
                        let imageURL = reviewWithUser.review.albumArt.flatMap { URL(string: $0) }

                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(
                                        ProgressView()
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    }

                    // レビュー文（帯部分）
                    if let reviewText = reviewWithUser.review.text {
                        Text(reviewText)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.7), Color.clear],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                    }
                }
                .cornerRadius(8)

                // 評価とユーザー名
                HStack {
                    // 評価（左寄せ）
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(reviewWithUser.review.rating) ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }

                    Spacer()

                    // ユーザー名（右寄せ）
                    Text("@\(reviewWithUser.user.displayName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Review Card Placeholder
struct ReviewCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Wide rectangular thumbnail placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .overlay(
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer()
                        // Placeholder for review text
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 12)
                            .padding(.horizontal, 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 12)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                    }
                )

            // Rating and username placeholder
            HStack {
                // Stars placeholder (left)
                HStack(spacing: 2) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }

                Spacer()

                // Username placeholder (right)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)
            }
        }
    }
}

// MARK: - Popular Album Card
struct PopularAlbumCard: View {
    let album: Album?

    var body: some View {
        NavigationLink(destination: album.map { AlbumDetailView(album: $0) }) {
            VStack(alignment: .leading, spacing: 6) {
                // アルバムアートワーク
                if let album = album, let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }

                Text(album?.title ?? "アルバム名")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(album?.artist ?? "アーティスト名")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reviewer Card
struct ReviewerCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                )

            Text("@username")
                .font(.caption)
                .fontWeight(.medium)

            Text("85件")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
