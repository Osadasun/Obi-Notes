//
//  ReviewDetailView.swift
//  Obi
//
//  レビュー詳細画面
//

import SwiftUI

struct ReviewDetailView: View {
    let review: Review

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // アルバム/トラック情報（タップでアルバム/トラック詳細へ）
                NavigationLink(destination: destinationView) {
                    albumHeader
                }
                .buttonStyle(.plain)

                // レビュー内容
                reviewContent
            }
        }
        .navigationTitle("レビュー詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Album Header

    private var albumHeader: some View {
        VStack(spacing: 16) {
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

            // アルバム/トラック情報
            VStack(alignment: .leading, spacing: 8) {
                Text(review.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)

                Text(review.artist)
                    .font(.title3)
                    .foregroundColor(.secondary)

                Text(review.targetType == .album ? "アルバム" : "楽曲")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Review Content

    private var reviewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 評価
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= Int(review.rating) ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(index <= Int(review.rating) ? .yellow : .gray)
                }

                Text(String(format: "%.1f", review.rating))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.leading, 8)
            }

            // レビュータイトル（見出し）
            if let reviewTitle = review.reviewTitle {
                Text(reviewTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // レビュー本文
            if let reviewText = review.text {
                Text(reviewText)
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("レビュー本文がありません")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 投稿日時
            VStack(alignment: .leading, spacing: 4) {
                Text("投稿日: \(review.createdAt.formatted(date: .long, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if review.updatedAt != review.createdAt {
                    Text("更新日: \(review.updatedAt.formatted(date: .long, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var destinationView: some View {
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

#Preview {
    NavigationStack {
        ReviewDetailView(review: Review(
            id: UUID(),
            userId: UUID(),
            targetType: .album,
            targetId: "1",
            rating: 4.5,
            reviewTitle: "最高のアルバム",
            text: "このアルバムは本当に素晴らしい。全ての曲が心に響く。特に3曲目の「夜に駆ける」は何度聴いても飽きない。",
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date(),
            albumArt: nil,
            title: "STRAY SHEEP",
            artist: "米津玄師"
        ))
    }
}
