//
//  ListDetailView.swift
//  Obi
//
//  リスト詳細画面（アルバムグリッド表示）
//

import SwiftUI

struct ListDetailView: View {
    let listType: MyListCategory
    var onNavigateToAlbum: ((Album) -> Void)? = nil
    @StateObject private var viewModel: ListDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingSearchSheet = false

    init(listType: MyListCategory, onNavigateToAlbum: ((Album) -> Void)? = nil) {
        self.listType = listType
        self.onNavigateToAlbum = onNavigateToAlbum
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
                MasonryLayout(spacing: 20) {
                    ForEach(viewModel.albums) { album in
                        if let onNavigate = onNavigateToAlbum {
                            Button(action: {
                                onNavigate(album)
                            }) {
                                AlbumGridItem(album: album)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(destination: AlbumDetailView(album: album)) {
                                AlbumGridItem(album: album)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                Color.clear
                    .frame(height: 120)
            }
        }
        .navigationTitle(listType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSearchSheet) {
            SearchView()
        }
        .task {
            await viewModel.loadAlbums()
        }
        .refreshable {
            await viewModel.loadAlbums()
        }
    }
}

#Preview {
    NavigationStack {
        ListDetailView(listType: .favorite)
    }
}
