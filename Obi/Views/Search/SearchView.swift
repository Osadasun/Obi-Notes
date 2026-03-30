//
//  SearchView.swift
//  Obi
//
//  検索画面
//

import SwiftUI

enum SearchFilter {
    case all
    case albumsOnly
    case tracksOnly
}

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    @Environment(\.dismiss) var dismiss
    let filter: SearchFilter
    let listId: UUID?
    let userAlbumId: String?

    init(filter: SearchFilter = .all, listId: UUID? = nil, userAlbumId: String? = nil) {
        self.filter = filter
        self.listId = listId
        self.userAlbumId = userAlbumId
        self._viewModel = StateObject(wrappedValue: SearchViewModel(listId: listId, userAlbumId: userAlbumId))
    }

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
                performSearch()
            }

            // 下部検索バー
            searchBar
            }
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

                TextField(searchPrompt, text: $viewModel.searchText)
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

    // MARK: - Helper Properties & Methods

    private var searchPrompt: String {
        switch filter {
        case .all:
            return "アルバム、アーティスト、楽曲"
        case .albumsOnly:
            return "アルバム、アーティストを検索"
        case .tracksOnly:
            return "楽曲を検索"
        }
    }

    private var searchPromptMessage: String {
        switch filter {
        case .all:
            return "アルバム、アーティスト、楽曲を検索"
        case .albumsOnly:
            return "アルバム、アーティストを検索"
        case .tracksOnly:
            return "楽曲を検索"
        }
    }

    private func performSearch() {
        switch filter {
        case .all:
            viewModel.search()
        case .albumsOnly:
            viewModel.searchAlbumsOnly()
        case .tracksOnly:
            viewModel.searchTracksOnly()
        }
    }

    // MARK: - State Views

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text(searchPromptMessage)
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
                if filter != .tracksOnly && !viewModel.albums.isEmpty {
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

                if filter != .albumsOnly && !viewModel.tracks.isEmpty {
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
        HStack(spacing: 12) {
            // NavigationLink用の透明ボタン
            NavigationLink(destination: AlbumDetailView(album: album)) {
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
                }
            }
            .buttonStyle(.plain)

            // 追加ボタン
            Button(action: {
                Task {
                    await viewModel.toggleAlbum(album)
                }
            }) {
                Image(systemName: viewModel.isAlbumAdded(album.id) ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .foregroundColor(viewModel.isAlbumAdded(album.id) ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)

        if album.id != viewModel.albums.last?.id {
            Divider()
                .padding(.leading, 116)
        }
    }

    @ViewBuilder
    private func searchResultTrackRow(track: Track) -> some View {
        HStack(spacing: 12) {
            // NavigationLink用の透明ボタン
            NavigationLink(destination: TrackDetailView(track: track)) {
                HStack(spacing: 12) {
                    // アルバムアート
                    if let artworkURL = track.artworkURL, let url = URL(string: artworkURL.replacingOccurrences(of: "{w}x{h}", with: "80x80")) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 56, height: 56)
                        .cornerRadius(6)
                    }

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
                }
            }
            .buttonStyle(.plain)

            // 追加ボタン
            Button(action: {
                Task {
                    await viewModel.toggleTrack(track)
                }
            }) {
                Image(systemName: viewModel.isTrackAdded(track.id) ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .foregroundColor(viewModel.isTrackAdded(track.id) ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)

        if track.id != viewModel.tracks.last?.id {
            Divider()
                .padding(.leading, 92)
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
