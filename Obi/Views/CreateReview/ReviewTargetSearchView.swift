//
//  ReviewTargetSearchView.swift
//  Obi
//
//  レビュー対象を選択するための検索画面
//

import SwiftUI

struct ReviewTargetSearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) var dismiss
    let onSelect: (MusicItem) -> Void

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    if !viewModel.isAuthorized {
                        // 権限リクエスト
                        authorizationView
                    } else if viewModel.searchText.isEmpty {
                        // 検索前の状態
                        emptyStateView
                    } else if viewModel.isLoading {
                        // ローディング
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        // エラー
                        errorView(errorMessage: errorMessage)
                    } else if viewModel.albums.isEmpty && viewModel.tracks.isEmpty {
                        // 結果なし
                        noResultsView
                    } else {
                        // 検索結果
                        searchResults
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .onChange(of: viewModel.searchText) { oldValue, newValue in
                    viewModel.search()
                }

                // 下部検索バー
                searchBar
            }
            .navigationTitle("レビュー対象を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                TextField("アルバム、アーティスト、楽曲", text: $viewModel.searchText)
                    .foregroundColor(.white)
                    .font(.body)
                    .accentColor(.white)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(Color.black)
            .cornerRadius(30)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
            .padding(.bottom, 0)
        }
    }

    // MARK: - State Views

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text("アルバム、アーティスト、楽曲を検索")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            Text("検索中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func errorView(errorMessage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.5))
            Text("エラーが発生しました")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text("「\(viewModel.searchText)」の検索結果が見つかりませんでした")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !viewModel.albums.isEmpty {
                    // アルバムセクション
                    Text("アルバム")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 12)

                    ForEach(viewModel.albums) { album in
                        searchResultAlbumRow(album: album)
                    }
                }

                if !viewModel.tracks.isEmpty {
                    // 曲セクション
                    Text("曲")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 12)

                    ForEach(viewModel.tracks) { track in
                        searchResultTrackRow(track: track)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func searchResultAlbumRow(album: Album) -> some View {
        Button(action: {
            let musicItem = MusicItem(
                id: album.id,
                title: album.title,
                artist: album.artist,
                artworkURL: album.artworkURL300,
                type: .album
            )
            onSelect(musicItem)
        }) {
            HStack(spacing: 12) {
                // アルバムアート
                if let artworkURL = album.artworkURL300, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(album.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)

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
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)

        if album.id != viewModel.albums.last?.id {
            Divider()
                .padding(.leading, 116)
        }
    }

    @ViewBuilder
    private func searchResultTrackRow(track: Track) -> some View {
        Button(action: {
            let musicItem = MusicItem(
                id: track.id,
                title: track.title,
                artist: track.artist,
                artworkURL: track.artworkURL,
                type: .track
            )
            onSelect(musicItem)
        }) {
            HStack(spacing: 12) {
                // CD型アートワーク
                DonutArtwork(imageUrl: track.artworkURL, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Text(track.artist)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        if let duration = track.durationFormatted {
                            Text("・")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(duration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)

        if track.id != viewModel.tracks.last?.id {
            Divider()
                .padding(.leading, 92)
        }
    }
}

#Preview {
    ReviewTargetSearchView(onSelect: { _ in })
}
