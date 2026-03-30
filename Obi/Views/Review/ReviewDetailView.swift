//
//  ReviewDetailView.swift
//  Obi
//
//  レビュー詳細画面（表示専用）
//

import SwiftUI

struct ReviewDetailView: View {
    @Environment(\.dismiss) var dismiss
    let review: Review

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // アルバム/楽曲情報
                HStack(spacing: 12) {
                    // アートワーク（楽曲の場合はCD型、アルバムの場合は角丸四角）
                    if review.targetType == .track {
                        // CD型アートワーク
                        DonutArtwork(imageUrl: review.albumArt, size: 80)
                    } else {
                        // アルバムの場合は従来通り
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
                    }

                    // タイトル・アーティスト
                    VStack(alignment: .leading, spacing: 4) {
                        Text(review.title)
                            .font(.headline)
                            .lineLimit(2)

                        Text(review.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text(review.targetType == .album ? "アルバム" : "楽曲")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Divider()
                    .padding(.vertical, 20)

                // 評価
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= Int(review.rating) ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(index <= Int(review.rating) ? .yellow : .gray)
                    }

                    Text("\(review.rating, specifier: "%.1f")")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                // タイトルとレビュー本文
                VStack(alignment: .leading, spacing: 0) {
                    // レビュータイトル
                    if let reviewTitle = review.reviewTitle, !reviewTitle.isEmpty {
                        Text(reviewTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }

                    // レビュー本文
                    if let text = review.text, !text.isEmpty {
                        Text(text)
                            .font(.body)
                            .padding(.horizontal, 24)
                            .padding(.top, (review.reviewTitle != nil && !review.reviewTitle!.isEmpty) ? 0 : 12)
                    }
                }
                .padding(.bottom, 24)

                Divider()
                    .padding(.vertical, 20)

                // 公開設定
                VStack(alignment: .leading, spacing: 12) {
                    Text("公開設定")
                        .font(.headline)

                    HStack {
                        Image(systemName: review.isPublic ? "eye" : "eye.slash")
                            .foregroundColor(.secondary)
                        Text(review.isPublic ? "全員に公開" : "非公開")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("レビュー")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        // TODO: 編集機能
                    }) {
                        Label("編集", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive, action: {
                        // TODO: 削除機能
                    }) {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
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
            reviewTitle: "素晴らしいアルバム",
            text: "このアルバムは本当に素晴らしい。全ての曲が心に響く。",
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date(),
            albumArt: nil,
            title: "STRAY SHEEP",
            artist: "米津玄師"
        ))
    }
}
