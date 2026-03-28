//
//  UserAlbumDetailView.swift
//  Obi
//
//  ユーザーアルバム詳細画面（曲一覧）
//

import SwiftUI

struct UserAlbumDetailView: View {
    let album: UserAlbum
    @StateObject private var viewModel: UserAlbumDetailViewModel
    @State private var showingMenu = false
    @State private var editedName: String
    @FocusState private var isNameFieldFocused: Bool

    init(album: UserAlbum) {
        self.album = album
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
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.9))
                        )

                    // タイトルとアーティスト名
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("タイトルなし", text: $editedName)
                            .font(.title)
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
                .padding(.top, 32)

                // 曲リスト
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.tracks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("まだ曲がありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 48)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.tracks) { track in
                            VStack(spacing: 0) {
                                // TODO: トラック詳細への遷移を実装
                                HStack(spacing: 12) {
                                    // アートワーク
                                    if let artworkURL = track.albumArt, let url = URL(string: artworkURL) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(6)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(track.title)
                                            .font(.body)
                                            .fontWeight(.medium)

                                        Text(track.artist)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)

                                if track.id != viewModel.tracks.last?.id {
                                    Divider()
                                        .padding(.leading, 86)
                                }
                            }
                        }
                    }
                }

                Color.clear.frame(height: 60)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingMenu = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .confirmationDialog("アルバムオプション", isPresented: $showingMenu) {
            Button("名前を変更") {
                // TODO: 名前変更機能
            }
            Button("色を変更") {
                // TODO: 色変更機能
            }
            Button("削除", role: .destructive) {
                // TODO: 削除機能
            }
            Button("キャンセル", role: .cancel) {}
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
