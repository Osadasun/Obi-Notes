//
//  ObiCard.swift
//  Obi
//
//  レコード帯風のレビューカード
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - ObiCard Style
enum ObiCardStyle {
    case horizontal  // 横長（アートワーク左、テキスト右）- トラック用
    case vertical    // 縦長（アートワーク上、テキスト下）
    case compact     // コンパクト（小さいサイズ）
    case overlay     // オーバーレイ（アートワーク上に帯とテキストを重ねる）- アルバム用

    var defaultHeight: CGFloat {
        switch self {
        case .horizontal:
            return 96
        case .vertical:
            return 200
        case .compact:
            return 80
        case .overlay:
            return 240
        }
    }

    // TargetTypeに基づいて適切なスタイルを返す
    static func forTargetType(_ targetType: TargetType) -> ObiCardStyle {
        switch targetType {
        case .album:
            return .overlay
        case .track:
            return .horizontal
        }
    }
}

struct ObiCard: View {
    let artworkURL: String?
    let reviewTitle: String
    let reviewText: String
    let cardHeight: CGFloat
    let style: ObiCardStyle

    @State private var obiColor: Color = Color(red: 0.4, green: 0.2, blue: 0.15)

    init(
        artworkURL: String?,
        reviewTitle: String,
        reviewText: String,
        cardHeight: CGFloat,
        style: ObiCardStyle = .horizontal
    ) {
        self.artworkURL = artworkURL
        self.reviewTitle = reviewTitle
        self.reviewText = reviewText
        self.cardHeight = cardHeight
        self.style = style
    }

    var body: some View {
        switch style {
        case .horizontal:
            horizontalLayout
        case .vertical:
            verticalLayout
        case .compact:
            compactLayout
        case .overlay:
            overlayLayout
        }
    }

    // MARK: - Horizontal Layout（横長レイアウト）
    private var horizontalLayout: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(obiColor)
            .frame(width: cardHeight, height: 96)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .overlay(
                HStack(alignment: .top, spacing: 12) {
                    artworkView(size: 72)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reviewTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(reviewText)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)

                        Spacer()
                    }

                    Spacer()
                }
                .padding(12)
            )
    }

    // MARK: - Vertical Layout（縦長レイアウト）
    private var verticalLayout: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(obiColor)
            .frame(width: cardHeight, height: 200)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .overlay(
                VStack(spacing: 12) {
                    artworkView(size: 120)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reviewTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(reviewText)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                .padding(12)
            )
    }

    // MARK: - Compact Layout（コンパクトレイアウト）
    private var compactLayout: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(obiColor)
            .frame(width: cardHeight, height: 80)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .overlay(
                HStack(alignment: .top, spacing: 8) {
                    artworkView(size: 56)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(reviewTitle)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(reviewText)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)

                        Spacer()
                    }

                    Spacer()
                }
                .padding(8)
            )
    }

    // MARK: - Overlay Layout（オーバーレイレイアウト）
    private var overlayLayout: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景のアートワーク（正方形）
            Group {
                if let urlString = artworkURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .onAppear {
                                    extractColorFromURL(url)
                                }
                        case .failure:
                            Color.gray.opacity(0.3)
                        case .empty:
                            Color.gray.opacity(0.3)
                        @unknown default:
                            Color.gray.opacity(0.3)
                        }
                    }
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: cardHeight, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 下部の帯（背景 + テキスト）
            VStack(alignment: .leading, spacing: 6) {
                Text(reviewTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(reviewText)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(obiColor)
        }
        .frame(width: cardHeight, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    // MARK: - Artwork View（共通アートワーク表示）
    @ViewBuilder
    private func artworkView(size: CGFloat) -> some View {
        Group {
            if let urlString = artworkURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .onAppear {
                                extractColorFromURL(url)
                            }
                    case .failure:
                        Color.gray.opacity(0.3)
                    case .empty:
                        Color.gray.opacity(0.3)
                    @unknown default:
                        Color.gray.opacity(0.3)
                    }
                }
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // URLから画像をダウンロードして色を抽出
    private func extractColorFromURL(_ url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data),
                   let dominantUIColor = uiImage.dominantColor() {
                    await MainActor.run {
                        obiColor = Color(uiColor: dominantUIColor)
                    }
                }
            } catch {
                print("❌ 画像の色抽出エラー: \(error)")
            }
        }
    }
}

// 文字列を2行に分割するヘルパー
extension String {
    func split2Lines() -> [String] {
        let maxCharsPerLine = 20
        if self.count <= maxCharsPerLine {
            return [self]
        } else {
            let firstLine = String(self.prefix(maxCharsPerLine))
            let secondLine = String(self.dropFirst(maxCharsPerLine).prefix(maxCharsPerLine))
            return [firstLine, secondLine]
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Overlay Style
            ObiCard(
                artworkURL: nil,
                reviewTitle: "オーバーレイ",
                reviewText: "アートワークの上に帯とテキストを重ねるレイアウトです。",
                cardHeight: 240,
                style: .overlay
            )

            // Horizontal Style
            ObiCard(
                artworkURL: nil,
                reviewTitle: "ホライゾンタル",
                reviewText: "横長のレイアウトです。アートワークが左側に配置されます。",
                cardHeight: 300,
                style: .horizontal
            )

            // Vertical Style
            ObiCard(
                artworkURL: nil,
                reviewTitle: "バーティカル",
                reviewText: "縦長のレイアウトです。アートワークが上部に配置されます。テキストは下部に表示されます。",
                cardHeight: 240,
                style: .vertical
            )

            // Compact Style
            ObiCard(
                artworkURL: nil,
                reviewTitle: "コンパクト",
                reviewText: "小さいサイズのレイアウトです。",
                cardHeight: 280,
                style: .compact
            )
        }
        .padding()
    }
}
