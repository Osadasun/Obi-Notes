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

struct ObiCard: View {
    let artworkURL: String?
    let reviewTitle: String
    let reviewText: String
    let cardHeight: CGFloat

    @State private var obiColor: Color = Color(red: 0.4, green: 0.2, blue: 0.15)

    var body: some View {
        // obiカラーの長方形背景
        RoundedRectangle(cornerRadius: 8)
            .fill(obiColor)
            .frame(width: cardHeight, height: 96)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .overlay(
                HStack(spacing: 12) {
                    // アートワーク部分（上部・正方形）
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                          .frame(width: 72)
                        

                    // テキスト部分（下部）
                    VStack(alignment: .leading, spacing: 4) {
                        

                        // レビュータイトル（縦書き風）
                        Text(reviewTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            
                            
                            .lineLimit(1)

                        // レビュー本文（縦書き風）
                        Text(reviewText)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                         
                         
                            .lineLimit(2)

                        Spacer()
                    }
                  
                    .background(Color.green.opacity(0.3))
                }
                .padding(12)
            )
    }

    // 画像から色を抽出
    private func extractColor(from image: Image) {
        // SwiftUI ImageをUIImageに変換して色を抽出
        let renderer = ImageRenderer(content: image)
        if let uiImage = renderer.uiImage,
           let dominantUIColor = uiImage.dominantColor() {
            obiColor = Color(uiColor: dominantUIColor)
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
    ObiCard(
        artworkURL: nil,
        reviewTitle: "タイトル",
        reviewText: "あああああああああああああああああああああああ",
        cardHeight: 240
    )
    .padding()
}
