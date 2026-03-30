//
//  DonutArtwork.swift
//  Obi
//
//  CD型（ドーナツ型）のアートワーク表示コンポーネント
//

import SwiftUI

struct DonutArtwork: View {
    let imageUrl: String?
    let size: CGFloat

    // CDの各部分のサイズ比率
    private var innerDiscRatio: CGFloat { 0.45 }  // 内側の透明円盤部分
    private var centerHoleRatio: CGFloat { 0.18 } // 中央の穴

    var body: some View {
        ZStack {
            if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                // アートワーク部分（ドーナツ型）
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: size, height: size)
                .mask(
                    Circle()
                        .fill(Color.black)
                        .overlay(
                            Circle()
                                .fill(Color.black)
                                .frame(width: size * innerDiscRatio, height: size * innerDiscRatio)
                                .blendMode(.destinationOut)
                        )
                )

                // 内側の透明円盤部分（薄いグレー）
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: size * innerDiscRatio, height: size * innerDiscRatio)

                // 中央の白い穴
                Circle()
                    .fill(Color.white)
                    .frame(width: size * centerHoleRatio, height: size * centerHoleRatio)
            } else {
                // プレースホルダー
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .mask(
                        Circle()
                            .fill(Color.black)
                            .overlay(
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: size * innerDiscRatio, height: size * innerDiscRatio)
                                    .blendMode(.destinationOut)
                            )
                    )

                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: size * innerDiscRatio, height: size * innerDiscRatio)

                Circle()
                    .fill(Color.white)
                    .frame(width: size * centerHoleRatio, height: size * centerHoleRatio)

                Image(systemName: "music.note")
                    .font(.system(size: size * 0.25))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        DonutArtwork(imageUrl: nil, size: 50)
        DonutArtwork(imageUrl: nil, size: 80)
        DonutArtwork(imageUrl: nil, size: 120)
    }
}
