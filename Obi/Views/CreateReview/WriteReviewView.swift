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
    @State private var showingSearchSheet = false

    init(musicItem: MusicItem) {
        self._viewModel = StateObject(wrappedValue: CreateReviewViewModel(musicItem: musicItem))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // アルバム/楽曲情報（タップで対象を変更）
                Button(action: {
                    showingSearchSheet = true
                }) {
                    HStack(spacing: 12) {
                        // アートワーク（楽曲の場合はCD型、アルバムの場合は角丸四角）
                        if viewModel.musicItem.type == .track {
                            // CD型アートワーク
                            DonutArtwork(imageUrl: viewModel.musicItem.artworkURL, size: 80)
                        } else {
                            // アルバムの場合は従来通り
                            if let artworkURL = viewModel.musicItem.artworkURL, let url = URL(string: artworkURL) {
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
                        }

                        // タイトル・アーティスト
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.musicItem.title)
                                .font(.headline)
                                .lineLimit(2)
                                .foregroundColor(.primary)

                            Text(viewModel.musicItem.artist)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)

                            Text(viewModel.musicItem.type.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // 変更アイコン
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, 20)

                // 評価
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
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                // タイトルとレビューをnote風に連結
                VStack(alignment: .leading, spacing: 0) {
                    TextField("タイトル", text: $viewModel.reviewTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)

                    TextEditor(text: $viewModel.reviewText)
                        .frame(minHeight: 200)
                        .font(.body)
                        .padding(.horizontal, 20)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .overlay(
                            Group {
                                if viewModel.reviewText.isEmpty {
                                    Text("この作品の感想を書いてみよう...")
                                        .foregroundColor(.gray)
                                        .font(.body)
                                        .padding(.horizontal, 24)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }

                Divider()
                    .padding(.vertical, 20)

                // 公開設定
                VStack(alignment: .leading, spacing: 12) {
                    Text("公開設定")
                        .font(.headline)

                    Toggle("全員に公開", isOn: $viewModel.isPublic)
                        .tint(.purple)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
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
        .sheet(isPresented: $showingSearchSheet) {
            ReviewTargetSearchView(onSelect: { selectedItem in
                viewModel.updateMusicItem(selectedItem)
                showingSearchSheet = false
            })
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
