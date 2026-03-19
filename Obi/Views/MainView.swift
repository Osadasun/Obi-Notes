//
//  MainView.swift
//  Obi
//
//  メインビュー（ヘッダー切り替え + フローティングボタン）
//

import SwiftUI
import Combine

struct MainView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var selectedFeed: Feed = .home
    @State private var showSearch = false
    @State private var bottomSpacerHeight: CGFloat = 50
    @State private var showProfile = false

    // UIPageViewControllerの内部余白を計算
    private func calculateBottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        // ホームボタンありデバイス: safe area bottom = 0, padding = -50
        // ホームボタンなしデバイス: safe area bottom = 34, padding = -(34 + 16) = -50
        return safeAreaBottom > 0 ? -(safeAreaBottom + 16) : -50
    }

    var body: some View {
        Group {
            if authViewModel.isLoading {
                // ローディング画面
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("読み込み中...")
                        .foregroundColor(.secondary)
                }
            } else if authViewModel.isAuthenticated {
                // 認証済み - メインビュー表示
                mainContent
            } else {
                // 未認証 - サインイン画面表示
                SignInView(authViewModel: authViewModel)
            }
        }
    }

    private var mainContent: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // メインコンテンツ
                VStack(spacing: 0) {
                    // ヘッダー（横並びタブ + プロフィール）
                    HStack(spacing: 0) {
                        // 横並びタブ
                        HorizontalTabBar(selectedFeed: $selectedFeed)

                        Spacer()

                        // プロフィールボタン
                        Button(action: {
                            showProfile = true
                        }) {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                )
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(Color(UIColor.systemBackground))

                    Divider()

                    // TabView ページャー
                    GeometryReader { geometry in
                        TabView(selection: $selectedFeed) {
                            HomeView(bottomSpacerHeight: bottomSpacerHeight)
                                .tag(Feed.home)

                            ObiView(bottomSpacerHeight: bottomSpacerHeight)
                                .tag(Feed.obi)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .ignoresSafeArea(.all)
                        .padding(.bottom, calculateBottomPadding(safeAreaBottom: geometry.safeAreaInsets.bottom))
                        .onAppear {
                            // スペーサーの高さを動的に設定
                            bottomSpacerHeight = abs(calculateBottomPadding(safeAreaBottom: geometry.safeAreaInsets.bottom))
                        }
                    }
                }
                .ignoresSafeArea(.all, edges: .bottom)

                // フローティングアクションボタン
                FloatingButton(
                    icon: "magnifyingglass",
                    backgroundColor: .white,
                    foregroundColor: .purple
                ) {
                    showSearch = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileView(authViewModel: authViewModel)
                }
            }
        }
    }
}

// MARK: - Feed Type
enum Feed: String, CaseIterable {
    case home = "Home"
    case obi = "Obi"
}

// MARK: - Horizontal Tab Bar
struct HorizontalTabBar: View {
    @Binding var selectedFeed: Feed

    var body: some View {
        HStack(spacing: 24) {
            ForEach(Feed.allCases, id: \.self) { feed in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFeed = feed
                    }
                }) {
                    Text(feed.rawValue)
                        .font(.title)
                        .fontWeight(selectedFeed == feed ? .bold : .regular)
                        .foregroundColor(selectedFeed == feed ? .primary : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Floating Button
struct FloatingButton: View {
    let icon: String
    let backgroundColor: Color
    let foregroundColor: Color
    var size: CGFloat = 48
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(foregroundColor)
            }
        }
    }
}

// MARK: - Obi View (My Reviews)
struct ObiView: View {
    let bottomSpacerHeight: CGFloat
    @StateObject private var viewModel = MyReviewsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("自分のレビュー")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if viewModel.reviews.isEmpty {
                    ContentUnavailableView(
                        "まだレビューがありません",
                        systemImage: "text.bubble",
                        description: Text("アルバムや楽曲を検索してレビューを書いてみよう")
                    )
                    .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.reviews) { review in
                        MyReviewCard(review: review)
                            .padding(.horizontal)
                    }
                }

                // TabViewの下部拡張分のスペーサー
                Color.clear
                    .frame(height: bottomSpacerHeight)
            }
        }
        .task {
            await viewModel.loadMyReviews()
        }
        .refreshable {
            await viewModel.loadMyReviews()
        }
    }
}

// MARK: - My Review Card
struct MyReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // アートワーク
                if let artworkURL = review.albumArt, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(review.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(review.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(review.rating) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        Text(String(format: "%.1f", review.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                }

                Spacer()
            }

            if let reviewText = review.text, !reviewText.isEmpty {
                Text(reviewText)
                    .font(.body)
                    .lineLimit(3)
            }

            Text(review.createdAt.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Create Review View (Placeholder)
struct CreateReviewView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("レビュー作成")
                    .font(.title)
                Text("ここでアルバムや楽曲のレビューを書きます")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("レビューを書く")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
}
