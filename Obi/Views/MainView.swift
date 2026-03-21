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
                    .background(.background)

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

// MARK: - Obi View (Lists)
struct ObiView: View {
    let bottomSpacerHeight: CGFloat
    @StateObject private var viewModel = ObiListViewModel()
    @State private var showCreateList = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        // デフォルトリスト + カスタムリスト（統一された2列グリッド）
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                            // デフォルトリスト
                            ListCard(
                                icon: "music.note.list",
                                title: "レビュー済み",
                                count: viewModel.reviewedCount,
                                color: .purple,
                                listType: .reviewed
                            )

                            ListCard(
                                icon: "heart.fill",
                                title: "お気に入り",
                                count: viewModel.favoriteCount,
                                color: .pink,
                                listType: .favorite
                            )

                            ListCard(
                                icon: "headphones",
                                title: "聴いた",
                                count: viewModel.listenedCount,
                                color: .blue,
                                listType: .listened
                            )

                            ListCard(
                                icon: "star.fill",
                                title: "聴きたい",
                                count: viewModel.wishlistCount,
                                color: .orange,
                                listType: .wishlist
                            )

                            // カスタムリスト
                            ForEach(viewModel.customLists) { list in
                                ListCard(
                                    title: list.name,
                                    count: viewModel.customListCounts[list.id] ?? 0,
                                    customList: list
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }

                    // TabViewの下部拡張分のスペーサー
                    Color.clear
                        .frame(height: bottomSpacerHeight)
                }
            }
            .task {
                await viewModel.loadListCounts()
            }
            .refreshable {
                await viewModel.loadListCounts()
            }

            // フローティングアクションボタン（リスト作成）
            FloatingButton(
                icon: "plus",
                backgroundColor: .white,
                foregroundColor: .purple
            ) {
                showCreateList = true
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showCreateList) {
            CreateListView()
        }
    }
}

// MARK: - Custom List Detail View (Placeholder)
struct CustomListDetailView: View {
    let list: MusicList

    var body: some View {
        Text("カスタムリスト: \(list.name)")
            .navigationTitle(list.name)
    }
}

// MARK: - List Card
struct ListCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    let destination: AnyView

    init(icon: String, title: String, count: Int, color: Color, listType: MyListCategory) {
        self.icon = icon
        self.title = title
        self.count = count
        self.color = color
        self.destination = AnyView(ListDetailView(listType: listType))
    }

    init(icon: String = "music.note.list", title: String, count: Int, color: Color = .purple, customList: MusicList) {
        self.icon = icon
        self.title = title
        self.count = count
        self.color = color
        self.destination = AnyView(CustomListDetailView(list: customList))
    }

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                // アイコンエリア（正方形）
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 40))
                            .foregroundColor(color)
                    )

                // タイトルと件数
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("\(count)件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - My Review Card (共通コンポーネント使用)
struct MyReviewCard: View {
    let review: Review

    var body: some View {
        ReviewCard(review: review)
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
