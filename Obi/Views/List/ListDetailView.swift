//
//  ListDetailView.swift
//  Obi
//
//  リスト詳細画面（アルバムグリッド表示）
//

import SwiftUI

struct ListDetailView: View {
    let listType: MyListCategory
    @StateObject private var viewModel: ListDetailViewModel
    @Environment(\.dismiss) var dismiss

    init(listType: MyListCategory) {
        self.listType = listType
        self._viewModel = StateObject(wrappedValue: ListDetailViewModel(listType: listType))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.albums.isEmpty {
                ContentUnavailableView(
                    "アルバムがありません",
                    systemImage: "music.note",
                    description: Text("アルバムを追加してみましょう")
                )
                .padding(.vertical, 40)
            } else {
                // 3列グリッド（画像のみ）
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(viewModel.albums) { album in
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            AlbumGridItem(album: album)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(listType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAlbums()
        }
        .refreshable {
            await viewModel.loadAlbums()
        }
    }
}

// MARK: - Album Grid Item
struct AlbumGridItem: View {
    let album: Album

    var body: some View {
        // 正方形のアルバムアート（タイトルなし）
        Group {
            if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            ProgressView()
                        )
                }
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        ListDetailView(listType: .favorite)
    }
}
