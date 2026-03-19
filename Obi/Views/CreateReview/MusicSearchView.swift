//
//  MusicSearchView.swift
//  Obi
//
//  音楽検索画面
//

import SwiftUI

struct MusicSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MusicSearchViewModel()
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("アルバムや楽曲を検索", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task {
                            await viewModel.searchMusic(query: searchText)
                        }
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearResults()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            Divider()

            // 検索結果
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchText.isEmpty {
                ContentUnavailableView(
                    "音楽を検索",
                    systemImage: "magnifyingglass",
                    description: Text("アルバムや楽曲を検索してレビューを書こう")
                )
            } else if viewModel.albums.isEmpty && viewModel.tracks.isEmpty {
                ContentUnavailableView(
                    "検索結果なし",
                    systemImage: "music.note.slash",
                    description: Text("「\(searchText)」に一致する音楽が見つかりませんでした")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // アルバム
                        if !viewModel.albums.isEmpty {
                            Text("アルバム")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.albums, id: \.id) { album in
                                NavigationLink(destination: WriteReviewView(musicItem: MusicItem(
                                    id: album.id,
                                    title: album.title,
                                    artist: album.artist,
                                    artworkURL: album.artworkURL,
                                    type: .album
                                ))) {
                                    MusicSearchResultRow(
                                        title: album.title,
                                        subtitle: album.artist,
                                        artworkURL: album.artworkURL,
                                        type: "アルバム"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // 楽曲
                        if !viewModel.tracks.isEmpty {
                            Text("楽曲")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, viewModel.albums.isEmpty ? 0 : 8)

                            ForEach(viewModel.tracks, id: \.id) { track in
                                NavigationLink(destination: WriteReviewView(musicItem: MusicItem(
                                    id: track.id,
                                    title: track.title,
                                    artist: track.artist,
                                    artworkURL: track.artworkURL,
                                    type: .track
                                ))) {
                                    MusicSearchResultRow(
                                        title: track.title,
                                        subtitle: "\(track.artist) - \(track.albumTitle ?? "")",
                                        artworkURL: track.artworkURL,
                                        type: "楽曲"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .navigationTitle("音楽を検索")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Search Result Row
struct MusicSearchResultRow: View {
    let title: String
    let subtitle: String
    let artworkURL: String?
    let type: String

    var body: some View {
        HStack(spacing: 12) {
                // アートワーク
                if let artworkURL = artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(4)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .cornerRadius(4)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }

                // タイトル・サブタイトル
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // タイプ表示
                Text(type)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        MusicSearchView()
    }
}
