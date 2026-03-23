//
//  WriteReviewView.swift
//  Obi
//
//  レビュー入力画面
//

import SwiftUI

struct WriteReviewView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: CreateReviewViewModel

    let musicItem: MusicItem

    init(musicItem: MusicItem) {
        self.musicItem = musicItem
        self._viewModel = StateObject(wrappedValue: CreateReviewViewModel(musicItem: musicItem))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // アルバム/楽曲情報
                HStack(spacing: 12) {
                    // アートワーク
                    if let artworkURL = musicItem.artworkURL, let url = URL(string: artworkURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.gray)
                            )
                    }

                    // タイトル・アーティスト
                    VStack(alignment: .leading, spacing: 4) {
                        Text(musicItem.title)
                            .font(.headline)
                            .lineLimit(2)

                        Text(musicItem.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text(musicItem.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Divider()

                // 評価
                VStack(alignment: .leading, spacing: 12) {
                    Text("評価")
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { index in
                            Button(action: {
                                viewModel.rating = Double(index)
                            }) {
                                Image(systemName: index <= Int(viewModel.rating) ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(index <= Int(viewModel.rating) ? .yellow : .gray)
                            }
                        }

                        Text("\(viewModel.rating, specifier: "%.1f")")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                    }
                }

                Divider()

                // レビュータイトル
                VStack(alignment: .leading, spacing: 12) {
                    Text("タイトル")
                        .font(.headline)

                    TextField("タイトルを入力...", text: $viewModel.reviewTitle)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 4)
                }

                Divider()

                // レビューコメント
                VStack(alignment: .leading, spacing: 12) {
                    Text("レビュー")
                        .font(.headline)

                    TextEditor(text: $viewModel.reviewText)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            Group {
                                if viewModel.reviewText.isEmpty {
                                    Text("この作品の感想を書いてみよう...")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 12)
                                        .padding(.top, 16)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }

                Divider()

                // 公開設定（将来の拡張用）
                VStack(alignment: .leading, spacing: 12) {
                    Text("公開設定")
                        .font(.headline)

                    Toggle("全員に公開", isOn: $viewModel.isPublic)
                        .tint(.purple)
                }
            }
            .padding()
        }
        .navigationTitle("レビューを書く")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("投稿") {
                    Task {
                        await viewModel.submitReview()
                        if viewModel.isSubmitted {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
                .fontWeight(.semibold)
            }
        }
        .overlay {
            if viewModel.isSubmitting {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("投稿中...")
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
        .alert("エラー", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Music Item (検索結果からレビュー画面に渡すデータ)
struct MusicItem {
    let id: String
    let title: String
    let artist: String
    let artworkURL: String?
    let type: MusicItemType

    enum MusicItemType: String {
        case album = "アルバム"
        case track = "楽曲"
    }
}

#Preview {
    NavigationStack {
        WriteReviewView(musicItem: MusicItem(
            id: "1",
            title: "STRAY SHEEP",
            artist: "米津玄師",
            artworkURL: nil,
            type: .album
        ))
    }
}
