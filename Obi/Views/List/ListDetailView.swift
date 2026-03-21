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
                .padding(.horizontal, 24)
                .padding(.top, 40)
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

#Preview {
    NavigationStack {
        ListDetailView(listType: .favorite)
    }
}
