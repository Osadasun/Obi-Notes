//
//  ObiListView.swift
//  Obi
//
//  全レビュー表示（Masonry風レイアウト）
//

import SwiftUI

struct ObiListView: View {
    @StateObject private var viewModel = ObiListDetailViewModel()

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
                        NavigationLink(destination: destinationView(for: review)) {
                            ObiCard(
                                artworkURL: review.albumArt,
                                reviewTitle: review.title,
                                reviewText: review.text ?? "レビューテキストがありません",
                                cardHeight: 240,
                                style: ObiCardStyle.forTargetType(review.targetType),
                                rating: review.rating
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .navigationTitle("レビュー一覧")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadReviews()
        }
        .refreshable {
            await viewModel.loadReviews()
        }
    }

    @ViewBuilder
    private func destinationView(for review: Review) -> some View {
        switch review.targetType {
        case .album:
            if let album = convertReviewToAlbum(review) {
                AlbumDetailView(album: album)
            } else {
                Text("アルバム情報が見つかりません")
            }
        case .track:
            if let track = convertReviewToTrack(review) {
                TrackDetailView(track: track)
            } else {
                Text("トラック情報が見つかりません")
            }
        }
    }

    private func convertReviewToAlbum(_ review: Review) -> Album? {
        return Album(
            id: review.targetId,
            title: review.title,
            artist: review.artist,
            artworkURL: review.albumArt,
            releaseDate: nil,
            genre: nil,
            trackCount: nil
        )
    }

    private func convertReviewToTrack(_ review: Review) -> Track? {
        return Track(
            id: review.targetId,
            title: review.title,
            artist: review.artist,
            albumTitle: nil,
            artworkURL: review.albumArt,
            duration: nil,
            trackNumber: nil
        )
    }
}

// MARK: - Masonry Layout
struct MasonryLayout: Layout {
    var spacing: CGFloat = 16

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let height = calculateHeight(width: width, subviews: subviews)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columnWidth = (bounds.width - spacing) / 2
        var columnHeights: [CGFloat] = [0, 0]

        for subview in subviews {
            let shortestColumn = columnHeights.firstIndex(of: columnHeights.min() ?? 0) ?? 0
            let x = bounds.minX + CGFloat(shortestColumn) * (columnWidth + spacing)
            let y = bounds.minY + columnHeights[shortestColumn]

            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))
            subview.place(at: CGPoint(x: x, y: y), proposal: .init(width: columnWidth, height: size.height))

            columnHeights[shortestColumn] += size.height + spacing
        }
    }

    private func calculateHeight(width: CGFloat, subviews: Subviews) -> CGFloat {
        let columnWidth = (width - spacing) / 2
        var columnHeights: [CGFloat] = [0, 0]

        for subview in subviews {
            let shortestColumn = columnHeights.firstIndex(of: columnHeights.min() ?? 0) ?? 0
            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))
            columnHeights[shortestColumn] += size.height + spacing
        }

        return columnHeights.max() ?? 0
    }
}

#Preview {
    NavigationStack {
        ObiListView()
    }
}
