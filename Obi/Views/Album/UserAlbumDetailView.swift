//
//  UserAlbumDetailView.swift
//  Obi
//
//  ユーザーアルバム詳細画面（曲一覧）
//

import SwiftUI

struct UserAlbumDetailView: View {
    let album: UserAlbum
    var onNavigateToTrack: ((Track) -> Void)? = nil
    var onNavigateToList: ((MusicList) -> Void)? = nil
    var onNavigateToUserAlbum: ((UserAlbum) -> Void)? = nil
    @StateObject private var viewModel: UserAlbumDetailViewModel
    @State private var editedName: String
    @State private var showingSearchSheet = false
    @FocusState private var isNameFieldFocused: Bool

    init(album: UserAlbum, onNavigateToTrack: ((Track) -> Void)? = nil, onNavigateToList: ((MusicList) -> Void)? = nil, onNavigateToUserAlbum: ((UserAlbum) -> Void)? = nil) {
        self.album = album
        self.onNavigateToTrack = onNavigateToTrack
        self.onNavigateToList = onNavigateToList
        self.onNavigateToUserAlbum = onNavigateToUserAlbum
        self._viewModel = StateObject(wrappedValue: UserAlbumDetailViewModel(albumId: album.id))
        self._editedName = State(initialValue: album.name)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // アルバムヘッダー
                VStack(spacing: 16) {
                    // カラー表示
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: album.colorHex))
                        .frame(width: 250, height: 250)
                        .shadow(radius: 10)
                        .overlay(
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.9))
                        )

                    // タイトルとアーティスト名
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("タイトルなし", text: $editedName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .focused($isNameFieldFocused)
                            .onSubmit {
                                Task {
                                    await updateAlbumName()
                                }
                            }

                        Text(album.artistName)
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("\(viewModel.tracks.count)曲")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)

                // 子リスト/アルバムセクション（存在する場合のみ表示）
                if !viewModel.childLists.isEmpty || !viewModel.childUserAlbums.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("リスト・アルバム")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20)
                        ], spacing: 20) {
                            // 子カスタムリスト
                            ForEach(viewModel.childLists) { childList in
                                Button(action: {
                                    onNavigateToList?(childList)
                                }) {
                                    ListCard(
                                        title: childList.name,
                                        count: 0,
                                        artworkURLs: []
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            // 子ユーザーアルバム
                            ForEach(viewModel.childUserAlbums) { childAlbum in
                                Button(action: {
                                    onNavigateToUserAlbum?(childAlbum)
                                }) {
                                    AlbumCard(
                                        title: childAlbum.name,
                                        artistName: childAlbum.artistName,
                                        colorHex: childAlbum.colorHex
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                // 曲を追加ボタン
                Button(action: {
                    showingSearchSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.body)
                        Text("曲を追加")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                // 曲リスト
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.tracks.isEmpty && viewModel.childLists.isEmpty && viewModel.childUserAlbums.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("まだ曲がありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 48)
                } else if viewModel.tracks.isEmpty {
                    // 子リスト/アルバムは存在するが曲がない場合は何も表示しない
                    EmptyView()
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.tracks) { item in
                            VStack(spacing: 0) {
                                Button(action: {
                                    let track = Track(
                                        id: item.targetId,
                                        title: item.title,
                                        artist: item.artist,
                                        albumTitle: nil,
                                        artworkURL: item.albumArt,
                                        duration: nil,
                                        trackNumber: nil,
                                        genre: nil
                                    )
                                    onNavigateToTrack?(track)
                                }) {
                                    HStack(spacing: 12) {
                                        // CD型アートワーク
                                        DonutArtwork(imageUrl: item.albumArt, size: 50)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .font(.body)
                                                .fontWeight(.medium)

                                            Text(item.artist)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)

                                if item.id != viewModel.tracks.last?.id {
                                    Divider()
                                        .padding(.leading, 86)
                                }
                            }
                        }
                    }
                }

                Color.clear.frame(height: 120)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        // TODO: 名前変更機能
                    }) {
                        Label("名前を変更", systemImage: "pencil")
                    }

                    Button(action: {
                        // TODO: 色変更機能
                    }) {
                        Label("色を変更", systemImage: "paintpalette")
                    }

                    Divider()

                    Button(role: .destructive, action: {
                        // TODO: 削除機能
                    }) {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchView(filter: .tracksOnly, userAlbumId: album.id)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
        .task {
            await viewModel.loadTracks()
        }
    }

    // MARK: - Helper Methods

    private func updateAlbumName() async {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 空の場合は「タイトルなし」として保存
        let finalName = trimmedName.isEmpty ? "タイトルなし" : trimmedName

        guard finalName != album.name else {
            editedName = album.name
            return
        }

        do {
            try await SupabaseService.shared.updateUserAlbum(
                albumId: album.id,
                name: finalName,
                colorHex: nil
            )
            print("✅ [UserAlbumDetailView] Album name updated: \(finalName)")
            editedName = finalName
        } catch {
            print("❌ [UserAlbumDetailView] Failed to update album name: \(error)")
            editedName = album.name
        }
    }
}

#Preview {
    NavigationStack {
        UserAlbumDetailView(album: UserAlbum(
            id: "1",
            userId: "test-user",
            name: "お気に入りのアルバム",
            artistName: "User",
            colorHex: "#9F7AEA",
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
