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
    let isPinned: Bool
    let isDefault: Bool
    let onPinToggle: (() -> Void)?
    let onEdit: (() -> Void)?
    let onMove: (() -> Void)?
    let onDelete: (() -> Void)?

    init(
        title: String,
        count: Int,
        artworkURLs: [String?] = [],
        isSelected: Bool = false,
        isPinned: Bool = false,
        isDefault: Bool = false,
        onPinToggle: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onMove: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.count = count
        self.artworkURLs = artworkURLs
        self.isSelected = isSelected
        self.isPinned = isPinned
        self.isDefault = isDefault
        self.onPinToggle = onPinToggle
        self.onEdit = onEdit
        self.onMove = onMove
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(spacing: 12) {
            // アルバムアート表示エリア（正方形）
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }

                    Text("\(count)件")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Menu {
                        Button(action: {
                            print("📌 [ListCard] Pin toggle tapped - title: \(title)")
                            onPinToggle?()
                        }) {
                            Label(isPinned ? "ピン留めを解除" : "ピン留め", systemImage: isPinned ? "pin.slash" : "pin")
                        }

                        if !isDefault {
                            Button(action: {
                                print("✏️ [ListCard] Edit tapped - title: \(title)")
                                onEdit?()
                            }) {
                                Label("編集", systemImage: "pencil")
                            }

                            Button(action: {
                                print("📂 [ListCard] Move tapped - title: \(title), onMove: \(onMove != nil)")
                                onMove?()
                            }) {
                                Label("移動", systemImage: "folder")
                            }

                            Button(role: .destructive, action: {
                                onDelete?()
                            }) {
                                Label("削除", systemImage: "trash")
                            }
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

    @ViewBuilder
    private var albumArtworkGrid: some View {
        let displayArtworks = Array(artworkURLs.prefix(3))

        // 3Dスタック風のレイアウト（最大3枚を重ねて表示）
        ZStack {
            // 3枚目（最背面・左寄り）
            if displayArtworks.count >= 3, let urlString = displayArtworks[2], let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .rotationEffect(.degrees(-8))
                .offset(x: -25, y: 5)
            }

            // 2枚目（中間・右寄り）
            if displayArtworks.count >= 2, let urlString = displayArtworks[1], let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .rotationEffect(.degrees(8))
                .offset(x: 25, y: 0)
            }

            // 1枚目（最前面・中央）
            if let urlString = displayArtworks.first ?? nil, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                .offset(y: -5)
            }
        }
        .frame(height: 100)
    }
}
