//
//  ProfileView.swift
//  Obi
//
//  プロフィール画面
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedSegment = 0
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // プロフィールヘッダー
                    VStack(spacing: 12) {
                        // アイコンとユーザー名
                        ZStack(alignment: .bottom) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                )

                            // ユーザー名をオーバーレイ
                            Text(viewModel.user?.displayName ?? "ユーザー名")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.5))
                                )
                                .offset(y: 10)
                        }

                        // 統計
                        HStack(spacing: 32) {
                            StatView(label: "レビュー", value: "\(viewModel.reviewCount)")
                            StatView(label: "平均評価", value: String(format: "★%.1f", viewModel.averageRating))
                            StatView(label: "リスト", value: "\(viewModel.listCount)")
                        }
                        .padding(.top, 8)
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
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if selectedSegment == 0 {
                        // レビュー一覧
                        if viewModel.reviews.isEmpty {
                            ContentUnavailableView(
                                "レビューがありません",
                                systemImage: "music.note.list",
                                description: Text("レビューを書いてみましょう")
                            )
                            .padding()
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(viewModel.reviews) { review in
                                    ReviewAlbumCard(review: review)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // リスト一覧
                        if viewModel.lists.isEmpty {
                            ContentUnavailableView(
                                "リストがありません",
                                systemImage: "list.bullet.rectangle",
                                description: Text("リストを作成してみましょう")
                            )
                            .padding()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.lists) { list in
                                    ListRowCard(list: list)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("マイページ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSignOutAlert = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task {
                await viewModel.loadProfileData()
            }
            .alert("サインアウト", isPresented: $showSignOutAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("サインアウト", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("本当にサインアウトしますか？")
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

// MARK: - Review Album Card
struct ReviewAlbumCard: View {
    let review: Review

    var body: some View {
        VStack(spacing: 8) {
            // アルバムアート
            AsyncImage(url: URL(string: review.albumArt ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.white)
                        )
                @unknown default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // レーティング
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Image(systemName: index < Int(review.rating) ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }

            // タイトル
            Text(review.title)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - List Row Card
struct ListRowCard: View {
    let list: MusicList

    var body: some View {
        HStack(spacing: 12) {
            // リストアイコン
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.purple.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: listIcon)
                        .font(.title2)
                        .foregroundColor(.purple)
                )

            // リスト情報
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.headline)
                Text(listTypeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var listIcon: String {
        switch list.defaultType {
        case .reviewed:
            return "star.fill"
        case .favorite:
            return "heart.fill"
        case .listened:
            return "checkmark.circle.fill"
        case .wishlist:
            return "bookmark.fill"
        case .none:
            return "list.bullet"
        }
    }

    private var listTypeText: String {
        switch list.defaultType {
        case .reviewed:
            return "レビュー済み"
        case .favorite:
            return "お気に入り"
        case .listened:
            return "聴いた"
        case .wishlist:
            return "聴きたい"
        case .none:
            return list.type == .default ? "デフォルト" : "カスタム"
        }
    }
}

#Preview {
    ProfileView(authViewModel: AuthenticationViewModel())
}
