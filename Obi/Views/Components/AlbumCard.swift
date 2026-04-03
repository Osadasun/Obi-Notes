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
    let colorHex: String
    let isSelected: Bool
    let isPinned: Bool
    let onPinToggle: (() -> Void)?
    let onEdit: (() -> Void)?
    let onMove: (() -> Void)?
    let onDelete: (() -> Void)?

    init(
        title: String,
        artistName: String,
        colorHex: String,
        isSelected: Bool = false,
        isPinned: Bool = false,
        onPinToggle: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onMove: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.artistName = artistName
        self.colorHex = colorHex
        self.isSelected = isSelected
        self.isPinned = isPinned
        self.onPinToggle = onPinToggle
        self.onEdit = onEdit
        self.onMove = onMove
        self.onDelete = onDelete
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

            // タイトルとアーティスト名
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }

                    Text(artistName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Menu {
                        Button(action: {
                            onPinToggle?()
                        }) {
                            Label(isPinned ? "ピン留めを解除" : "ピン留め", systemImage: isPinned ? "pin.slash" : "pin")
                        }

                        Button(action: {
                            onEdit?()
                        }) {
                            Label("編集", systemImage: "pencil")
                        }

                        Button(action: {
                            onMove?()
                        }) {
                            Label("移動", systemImage: "folder")
                        }

                        Button(role: .destructive, action: {
                            onDelete?()
                        }) {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        AlbumCard(
            title: "お気に入り",
            artistName: "User",
            colorHex: "#9F7AEA",
            isSelected: false
        )
        .frame(width: 150)

        AlbumCard(
            title: "2024ベスト",
            artistName: "User",
            colorHex: "#48BB78",
            isSelected: true
        )
        .frame(width: 150)
    }
    .padding()
}
