//
//  AddAlbumFromShareView.swift
//  Obi
//
//  Share Extensionから開かれたときのアルバム追加画面
//

import SwiftUI

struct AddAlbumFromShareView: View {
    let albumId: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddAlbumFromShareViewModel

    init(albumId: String) {
        self.albumId = albumId
        self._viewModel = StateObject(wrappedValue: AddAlbumFromShareViewModel(albumId: albumId))
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("アルバム情報を取得中...")
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
                } else if let album = viewModel.album {
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
                                    await viewModel.addToSelectedList()
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
            await viewModel.loadAlbum()
            await viewModel.loadLists()
        }
    }
}

#Preview {
    AddAlbumFromShareView(albumId: "1878613520")
}
