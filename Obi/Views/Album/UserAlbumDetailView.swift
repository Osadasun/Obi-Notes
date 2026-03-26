//
//  UserAlbumDetailView.swift
//  Obi
//
//  ユーザーアルバム詳細画面（曲一覧）
//

import SwiftUI

struct UserAlbumDetailView: View {
    let album: UserAlbum
    @StateObject private var viewModel: UserAlbumDetailViewModel

    init(album: UserAlbum) {
        self.album = album
        self._viewModel = StateObject(wrappedValue: UserAlbumDetailViewModel(albumId: album.id))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // アルバムヘッダー
                VStack(spacing: 16) {
                    // カラー表示
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: album.colorHex))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.9))
                        )

                    // タイトル
                    Text(album.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("\(viewModel.tracks.count)曲")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                // 曲リスト
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.tracks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("まだ曲がありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 48)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.tracks) { track in
                            VStack(spacing: 0) {
                                // TODO: トラック詳細への遷移を実装
                                HStack(spacing: 12) {
                                    // アートワーク
                                    if let artworkURL = track.albumArt, let url = URL(string: artworkURL) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(6)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(track.title)
                                            .font(.body)
                                            .fontWeight(.medium)

                                        Text(track.artist)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)

                                if track.id != viewModel.tracks.last?.id {
                                    Divider()
                                        .padding(.leading, 86)
                                }
                            }
                        }
                    }
                }

                Color.clear.frame(height: 60)
            }
        }
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadTracks()
        }
    }
}

#Preview {
    NavigationStack {
        UserAlbumDetailView(album: UserAlbum(
            id: "1",
            userId: "test-user",
            name: "お気に入りのアルバム",
            colorHex: "#9F7AEA",
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
