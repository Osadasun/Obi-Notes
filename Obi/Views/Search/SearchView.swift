//
//  SearchView.swift
//  Obi
//
//  検索画面
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if !viewModel.isAuthorized {
                    // 権限リクエスト
                    authorizationView
                } else if viewModel.searchText.isEmpty {
                    // 検索前の状態
                    ContentUnavailableView(
                        "音楽を検索",
                        systemImage: "magnifyingglass",
                        description: Text("アルバムやアーティストを検索してレビューを書こう")
                    )
                } else if viewModel.isLoading {
                    // ローディング
                    ProgressView("検索中...")
                } else if let errorMessage = viewModel.errorMessage {
                    // エラー
                    ContentUnavailableView(
                        "エラーが発生しました",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if viewModel.albums.isEmpty && viewModel.tracks.isEmpty {
                    // 結果なし
                    ContentUnavailableView(
                        "結果が見つかりませんでした",
                        systemImage: "music.note.list",
                        description: Text("別のキーワードで検索してみてください")
                    )
                } else {
                    // 検索結果
                    searchResults
                }
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "アルバム、アーティスト、楽曲")
            .onSubmit(of: .search) {
                viewModel.search()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Authorization View

    private var authorizationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            Text("Apple Musicへのアクセス")
                .font(.title2)
                .fontWeight(.bold)

            Text("音楽情報を取得してレビューを作成するために、Apple Musicへのアクセスを許可してください")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button(action: {
                Task {
                    await viewModel.requestAuthorization()
                }
            }) {
                Text("許可する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Search Results

    private var searchResults: some View {
        List {
            if !viewModel.albums.isEmpty {
                Section("アルバム (\(viewModel.albums.count))") {
                    ForEach(viewModel.albums) { album in
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            AlbumRow(album: album)
                        }
                    }
                }
            }

            if !viewModel.tracks.isEmpty {
                Section("楽曲 (\(viewModel.tracks.count))") {
                    ForEach(viewModel.tracks) { track in
                        TrackRow(track: track)
                    }
                }
            }
        }
    }
}

// MARK: - Album Row
struct AlbumRow: View {
    let album: Album

    var body: some View {
        HStack(spacing: 12) {
            // アルバムアート
            if let artworkURL = album.artworkURL300, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(album.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let year = album.releaseDate?.formatted(.dateTime.year()) {
                    Text(year)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Track Row
struct TrackRow: View {
    let track: Track
    var averageRating: Double? = nil

    var body: some View {
        HStack(spacing: 12) {
            // トラック番号（アルバムアートなし）
            if let trackNumber = track.trackNumber {
                Text("\(trackNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.body)
                    .lineLimit(1)

                if let duration = track.durationFormatted {
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 評価表示
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", averageRating ?? 0.0))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SearchView()
}
