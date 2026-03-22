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
    @State private var showingSearchSheet = false

    init(listType: MyListCategory) {
        self.listType = listType
        self._viewModel = StateObject(wrappedValue: ListDetailViewModel(listType: listType))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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

            // フローティングアクションボタン
            Button(action: {
                showingSearchSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.purple)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
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
