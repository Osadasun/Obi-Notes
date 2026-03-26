//
//  AlbumCard.swift
//  Obi
//
//  ユーザーアルバムカード共通コンポーネント
//

import SwiftUI

struct AlbumCard: View {
    let title: String
    let artistName: String
    let count: Int
    let colorHex: String
    let isSelected: Bool

    init(
        title: String,
        artistName: String,
        count: Int,
        colorHex: String,
        isSelected: Bool = false
    ) {
        self.title = title
        self.artistName = artistName
        self.count = count
        self.colorHex = colorHex
        self.isSelected = isSelected
    }

    var body: some View {
        VStack(spacing: 12) {
            // カラー表示エリア（正方形）
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: colorHex))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    ZStack {
                        // アルバムアイコン
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.9))

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

            // タイトル、アーティスト名、件数
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text("\(count)曲")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        AlbumCard(
            title: "お気に入り",
            artistName: "User",
            count: 12,
            colorHex: "#9F7AEA",
            isSelected: false
        )
        .frame(width: 150)

        AlbumCard(
            title: "2024ベスト",
            artistName: "User",
            count: 8,
            colorHex: "#48BB78",
            isSelected: true
        )
        .frame(width: 150)
    }
    .padding()
}
