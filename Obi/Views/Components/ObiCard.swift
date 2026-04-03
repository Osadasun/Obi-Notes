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
    let rating: Double?
    let useFlexibleWidth: Bool

    @State private var obiColor: Color = Color(red: 0.4, green: 0.2, blue: 0.15)

    init(
        artworkURL: String?,
        reviewTitle: String,
        reviewText: String,
        cardHeight: CGFloat,
        style: ObiCardStyle = .horizontal,
        rating: Double? = nil,
        useFlexibleWidth: Bool = false
    ) {
        self.artworkURL = artworkURL
        self.reviewTitle = reviewTitle
        self.reviewText = reviewText
        self.cardHeight = cardHeight
        self.style = style
        self.rating = rating
        self.useFlexibleWidth = useFlexibleWidth
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
        // cardHeightに基づいてテキストサイズを動的に変更
        let titleSize: CGFloat = cardHeight > 300 ? 18 : 15
        let textSize: CGFloat = cardHeight > 300 ? 14 : 12
        let artworkSize: CGFloat = cardHeight > 300 ? 72 : 60
        let spacing: CGFloat = cardHeight > 300 ? 12 : 10
        let padding: CGFloat = cardHeight > 300 ? 12 : 10
        let cardHeightValue: CGFloat = cardHeight > 300 ? 96 : 80
        let cardWidthValue: CGFloat = cardHeight * 0.75

        return RoundedRectangle(cornerRadius: 8)
            .fill(obiColor)
            .frame(width: cardWidthValue, height: cardHeightValue)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .overlay(
                HStack(alignment: .top, spacing: spacing) {
                    artworkView(size: artworkSize)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reviewTitle)
                            .font(.system(size: titleSize, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(reviewText)
                            .font(.system(size: textSize))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)

                        Spacer()
                    }

                    Spacer()
                }
                .padding(padding)
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
        // cardHeightに基づいてテキストサイズを動的に変更
        let titleSize: CGFloat = cardHeight > 300 ? 18 : 15
        let ratingSize: CGFloat = cardHeight > 300 ? 14 : 12
        let textSize: CGFloat = cardHeight > 300 ? 14 : 12
        let vSpacing: CGFloat = cardHeight > 300 ? 6 : 4
        let hSpacing: CGFloat = cardHeight > 300 ? 8 : 6
        let hPadding: CGFloat = cardHeight > 300 ? 16 : 12
        let vPadding: CGFloat = cardHeight > 300 ? 12 : 8
        let minSpacing: CGFloat = cardHeight > 300 ? 8 : 4

        if useFlexibleWidth {
            return AnyView(
                GeometryReader { geometry in
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
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // 下部の帯（背景 + テキスト）
                        VStack(alignment: .leading, spacing: vSpacing) {
                            HStack(alignment: .center, spacing: hSpacing) {
                                Text(reviewTitle)
                                    .font(.system(size: titleSize, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Spacer(minLength: minSpacing)

                                if let rating = rating {
                                    Text(String(format: "★ %.1f", rating))
                                        .font(.system(size: ratingSize, weight: .semibold))
                                        .foregroundColor(.white)
                                        .fixedSize()
                                }
                            }

                            Text(reviewText)
                                .font(.system(size: textSize))
                                .foregroundColor(.white.opacity(0.95))
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, hPadding)
                        .padding(.vertical, vPadding)
                        .background(obiColor)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .aspectRatio(1, contentMode: .fit)
            )
        } else {
            return AnyView(
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
                    .frame(width: cardHeight * 0.75, height: cardHeight * 0.75)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // 下部の帯（背景 + テキスト）
                    VStack(alignment: .leading, spacing: vSpacing) {
                        HStack(alignment: .center, spacing: hSpacing) {
                            Text(reviewTitle)
                                .font(.system(size: titleSize, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer(minLength: minSpacing)

                            if let rating = rating {
                                Text(String(format: "★ %.1f", rating))
                                    .font(.system(size: ratingSize, weight: .semibold))
                                    .foregroundColor(.white)
                                    .fixedSize()
                            }
                        }

                        Text(reviewText)
                            .font(.system(size: textSize))
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, hPadding)
                    .padding(.vertical, vPadding)
                    .background(obiColor)
                }
                .frame(width: cardHeight * 0.75, height: cardHeight * 0.75)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            )
        }
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
