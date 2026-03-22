//
//  ListCard.swift
//  Obi
//
//  リストカード共通コンポーネント
//

import SwiftUI

struct ListCard: View {
    let title: String
    let count: Int
    let artworkURLs: [String?]
    let isSelected: Bool

    init(
        title: String,
        count: Int,
        artworkURLs: [String?] = [],
        isSelected: Bool = false
    ) {
        self.title = title
        self.count = count
        self.artworkURLs = artworkURLs
        self.isSelected = isSelected
    }

    var body: some View {
        VStack(spacing: 12) {
            // アルバムアート表示エリア（正方形）
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    ZStack {
                        // アルバムアートを最大3つ表示
                        if artworkURLs.isEmpty {
                            // アルバムがない場合はプレースホルダー
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                        } else {
                            albumArtworkGrid
                        }

                        // 選択時のチェックマーク
                        if isSelected {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 24, height: 24)
                                        )
                                        .padding(8)
                                }
                                Spacer()
                            }
                        }
                    }
                )
                .clipped()

            // タイトルと件数
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("\(count)件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var albumArtworkGrid: some View {
        GeometryReader { geometry in
            let size = geometry.size.width
            let displayArtworks = Array(artworkURLs.prefix(3))

            if displayArtworks.count == 1 {
                // 1枚の場合：全体に表示
                if let urlString = displayArtworks[0], let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: size, height: size)
                }
            } else if displayArtworks.count == 2 {
                // 2枚の場合：左右に分割
                HStack(spacing: 2) {
                    ForEach(0..<2, id: \.self) { index in
                        if let urlString = displayArtworks[index], let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: size / 2 - 1, height: size)
                        }
                    }
                }
            } else if displayArtworks.count == 3 {
                // 3枚の場合：左に1枚、右に2枚縦並び
                HStack(spacing: 2) {
                    // 左側：1枚目
                    if let urlString = displayArtworks[0], let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: size / 2 - 1, height: size)
                    }

                    // 右側：2枚縦並び
                    VStack(spacing: 2) {
                        ForEach(1..<3, id: \.self) { index in
                            if let urlString = displayArtworks[index], let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: size / 2 - 1, height: size / 2 - 1)
                            }
                        }
                    }
                }
            }
        }
    }
}
