//
//  AddToListView.swift
//  Obi
//
//  リスト追加画面
//

import SwiftUI

struct AddToListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddToListViewModel

    init(album: Album) {
        _viewModel = StateObject(wrappedValue: AddToListViewModel(targetType: .album, targetId: album.id, title: album.title, artist: album.artist, artworkURL: album.artworkURL))
    }

    init(track: Track) {
        _viewModel = StateObject(wrappedValue: AddToListViewModel(targetType: .track, targetId: track.id, title: track.title, artist: track.artist, artworkURL: track.artworkURL))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else if viewModel.lists.isEmpty {
                        ContentUnavailableView(
                            "リストがありません",
                            systemImage: "music.note.list",
                            description: Text("先にリストを作成してください")
                        )
                        .padding(.top, 100)
                    } else {
                        VStack(alignment: .leading, spacing: 20) {
                            // デフォルトリスト
                            if !viewModel.defaultLists.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("デフォルトリスト")
                                        .font(.headline)
                                        .padding(.horizontal, 24)

                                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                                        ForEach(viewModel.defaultLists) { list in
                                            ListCard(
                                                icon: viewModel.iconForList(list),
                                                title: list.name,
                                                count: viewModel.listCounts[list.id] ?? 0,
                                                color: viewModel.colorForList(list),
                                                isSelected: viewModel.addedListIds.contains(list.id),
                                                action: {
                                                    Task {
                                                        await viewModel.toggleList(list)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }

                            // カスタムリスト
                            if !viewModel.customLists.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("カスタムリスト")
                                        .font(.headline)
                                        .padding(.horizontal, 24)

                                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                                        ForEach(viewModel.customLists) { list in
                                            ListCard(
                                                icon: viewModel.iconForList(list),
                                                title: list.name,
                                                count: viewModel.listCounts[list.id] ?? 0,
                                                color: viewModel.colorForList(list),
                                                isSelected: viewModel.addedListIds.contains(list.id),
                                                action: {
                                                    Task {
                                                        await viewModel.toggleList(list)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                        .padding(.top, 40)
                    }
                }
            }
            .navigationTitle("リストに追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadLists()
            }
        }
    }
}

#Preview {
    AddToListView(album: Album(
        id: "1",
        title: "Abbey Road",
        artist: "The Beatles",
        artworkURL: "https://example.com/artwork.jpg",
        releaseDate: Date(),
        genre: "Rock",
        trackCount: 17
    ))
}
