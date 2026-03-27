//
//  AddAlbumFromShareView.swift
//  Obi
//
//  Share Extensionから開かれたときのアルバム追加画面
//

import SwiftUI

struct AddAlbumFromShareView: View {
    let musicId: String
    let musicType: MusicTargetType
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddAlbumFromShareViewModel

    init(musicId: String, musicType: MusicTargetType) {
        self.musicId = musicId
        self.musicType = musicType
        self._viewModel = StateObject(wrappedValue: AddAlbumFromShareViewModel(musicId: musicId, musicType: musicType))
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(musicType == .album ? "アルバム情報を取得中..." : "トラック情報を取得中...")
                            .foregroundColor(.secondary)
                    }
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)

                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("閉じる") {
                            dismiss()
                        }
                        .padding()
                    }
                } else if musicType == .album, let album = viewModel.album {
                    ScrollView {
                        VStack(spacing: 24) {
                            // アートワーク
                            if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                }
                                .frame(width: 200, height: 200)
                                .cornerRadius(12)
                            }

                            // アルバム情報
                            VStack(spacing: 8) {
                                Text(album.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)

                                Text(album.artist)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            // リスト選択
                            VStack(alignment: .leading, spacing: 8) {
                                Text("追加先のリスト")
                                    .font(.headline)
                                    .padding(.horizontal, 24)

                                if viewModel.isLoadingLists {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                    .padding()
                                } else {
                                    ForEach(viewModel.lists) { list in
                                        Button(action: {
                                            viewModel.selectedList = list
                                        }) {
                                            HStack {
                                                Image(systemName: viewModel.selectedList?.id == list.id ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(viewModel.selectedList?.id == list.id ? .purple : .gray)

                                                Text(list.name)
                                                    .foregroundColor(.primary)

                                                Spacer()
                                            }
                                            .padding()
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                            }

                            // 追加ボタン
                            Button(action: {
                                Task {
                                    await viewModel.addToSelectedDestination()
                                }
                            }) {
                                Text("追加")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(viewModel.selectedList != nil ? Color.purple : Color.gray)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                            .disabled(viewModel.isAdding || viewModel.selectedList == nil)

                            if viewModel.isAdding {
                                ProgressView("追加中...")
                            }

                            if viewModel.addSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("追加しました")
                                        .foregroundColor(.green)
                                }
                                .padding()
                            }
                        }
                        .padding(.top, 32)
                    }
                } else if musicType == .track, let track = viewModel.track {
                    ScrollView {
                        VStack(spacing: 24) {
                            // アートワーク
                            if let artworkURL = track.artworkURL, let url = URL(string: artworkURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                }
                                .frame(width: 200, height: 200)
                                .cornerRadius(12)
                            }

                            // トラック情報
                            VStack(spacing: 8) {
                                Text(track.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)

                                Text(track.artist)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            // ユーザーアルバム選択
                            VStack(alignment: .leading, spacing: 8) {
                                Text("追加先のアルバム")
                                    .font(.headline)
                                    .padding(.horizontal, 24)

                                if viewModel.isLoadingLists {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                    .padding()
                                } else if viewModel.userAlbums.isEmpty {
                                    VStack(spacing: 12) {
                                        Text("アルバムがありません")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("先にカスタムアルバムを作成してください")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                } else {
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 16),
                                        GridItem(.flexible(), spacing: 16)
                                    ], spacing: 16) {
                                        ForEach(viewModel.userAlbums) { album in
                                            Button(action: {
                                                viewModel.selectedUserAlbum = album
                                            }) {
                                                AlbumCard(
                                                    title: album.name,
                                                    artistName: album.artistName,
                                                    colorHex: album.colorHex,
                                                    isSelected: viewModel.selectedUserAlbum?.id == album.id
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }

                            // 追加ボタン
                            Button(action: {
                                Task {
                                    await viewModel.addToSelectedDestination()
                                }
                            }) {
                                Text("追加")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(viewModel.selectedUserAlbum != nil ? Color.purple : Color.gray)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                            .disabled(viewModel.isAdding || viewModel.selectedUserAlbum == nil)

                            if viewModel.isAdding {
                                ProgressView("追加中...")
                            }

                            if viewModel.addSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("追加しました")
                                        .foregroundColor(.green)
                                }
                                .padding()
                            }
                        }
                        .padding(.top, 32)
                    }
                }
            }
            .navigationTitle("Obiに追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadMusic()
            await viewModel.loadLists()
        }
    }
}

#Preview {
    AddAlbumFromShareView(musicId: "1878613520", musicType: .album)
}
