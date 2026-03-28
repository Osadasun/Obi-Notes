//
//  SearchHistoryOverlay.swift
//  Obi
//
//  検索フォーカス時に表示される検索履歴オーバーレイ
//

import SwiftUI

struct SearchHistoryOverlay: View {
    @ObservedObject var viewModel: SearchHistoryViewModel
    @StateObject private var searchViewModel = MusicSearchViewModel()
    @Binding var searchText: String
    let onSelectSearch: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // コンテンツ
            if !searchText.isEmpty {
                // 検索中: 検索結果を表示
                searchResultsView
            } else {
                // 最近の検索
                recentSearchesView
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onChange(of: searchText) { _, newValue in
            Task {
                await searchViewModel.searchMusic(query: newValue)
            }
        }
    }

    @ViewBuilder
    private var recentSearchesView: some View {
        if viewModel.recentSearches.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.5))
                Text("最近の検索はありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentSearches, id: \.self) { query in
                        searchHistoryRow(query: query)
                    }
                }
                .padding(.top, 24)
            }
        }
    }

    @ViewBuilder
    private var searchResultsView: some View {
        if searchViewModel.isLoading {
            // ローディング中
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("検索中...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else if let errorMessage = searchViewModel.errorMessage {
            // エラー表示
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
        } else if searchViewModel.albums.isEmpty && searchViewModel.tracks.isEmpty {
            // 検索結果なし
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.5))
                Text("「\(searchText)」の検索結果が見つかりませんでした")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            // 検索結果表示
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // アルバム結果
                    if !searchViewModel.albums.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("アルバム")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)

                            VStack(spacing: 0) {
                                ForEach(searchViewModel.albums) { album in
                                    searchResultAlbumRow(album: album)
                                }
                            }
                        }
                    }

                    // トラック結果
                    if !searchViewModel.tracks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("楽曲")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)

                            VStack(spacing: 0) {
                                ForEach(searchViewModel.tracks) { track in
                                    searchResultTrackRow(track: track)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private func searchHistoryRow(query: String) -> some View {
        Button(action: {
            onSelectSearch(query)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text(query)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    viewModel.removeSearch(query)
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)

        if query != viewModel.recentSearches.last {
            Divider()
                .padding(.leading, 24)
        }
    }

    @ViewBuilder
    private func searchResultAlbumRow(album: Album) -> some View {
        NavigationLink(destination: AlbumDetailView(album: album)) {
            HStack(spacing: 12) {
                // アルバムアート
                if let artworkURL = album.artworkURL300, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }

                // タイトルとアーティスト
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(album.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)

        if album.id != searchViewModel.albums.last?.id {
            Divider()
                .padding(.leading, 92)
        }
    }

    @ViewBuilder
    private func searchResultTrackRow(track: Track) -> some View {
        NavigationLink(destination: TrackDetailView(track: track)) {
            HStack(spacing: 12) {
                // アルバムアート
                if let artworkURL = track.artworkURL, let url = URL(string: artworkURL.replacingOccurrences(of: "{w}x{h}", with: "56x56")) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }

                // タイトルとアーティスト
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(track.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        if let albumTitle = track.albumTitle {
                            Text("•")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(albumTitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)

        if track.id != searchViewModel.tracks.last?.id {
            Divider()
                .padding(.leading, 92)
        }
    }
}
