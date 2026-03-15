//
//  ProfileView.swift
//  Obi
//
//  プロフィール画面
//

import SwiftUI

struct ProfileView: View {
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // プロフィールヘッダー
                    VStack(spacing: 12) {
                        // アイコン
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            )

                        // ユーザー名
                        Text("ユーザー名")
                            .font(.title2)
                            .fontWeight(.bold)

                        // 自己紹介
                        Text("音楽が大好きです")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // 統計
                        HStack(spacing: 32) {
                            StatView(label: "レビュー", value: "85")
                            StatView(label: "平均評価", value: "★4.2")
                            StatView(label: "リスト", value: "12")
                        }
                        .padding(.top, 8)

                        // 編集ボタン
                        Button(action: {
                            // TODO: プロフィール編集
                        }) {
                            Text("プロフィールを編集")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    .padding()

                    // セグメントコントロール
                    Picker("Content", selection: $selectedSegment) {
                        Text("レビュー").tag(0)
                        Text("リスト").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // コンテンツ
                    if selectedSegment == 0 {
                        // レビュー一覧
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(0..<12) { index in
                                PopularAlbumCard(album: nil)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // リスト一覧
                        VStack(spacing: 12) {
                            ForEach(0..<5) { index in
                                ListCardPlaceholder()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("マイページ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: 設定画面
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}

// MARK: - Stat View
struct StatView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - List Card Placeholder
struct ListCardPlaceholder: View {
    var body: some View {
        HStack(spacing: 12) {
            // サムネイル（3x3のアルバムアート）
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                ForEach(0..<9) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text("リスト名")
                    .font(.headline)
                Text("10曲")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    ProfileView()
}
