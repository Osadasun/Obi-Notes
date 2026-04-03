//
//  AlbumGridItem.swift
//  Obi
//
//  アルバムグリッド表示用の共通コンポーネント
//

import SwiftUI

struct AlbumGridItem: View {
    let album: Album

    var body: some View {
        VStack(spacing: 12) {
            // 正方形のアルバムアート
            Group {
                if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                ProgressView()
                            )
                    }
                    .aspectRatio(1, contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // タイトルとアーティスト名
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(album.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
