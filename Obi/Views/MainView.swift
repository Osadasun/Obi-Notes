//
//  MainView.swift
//  Obi
//
//  メインビュー（ヘッダー切り替え + フローティングボタン）
//

import SwiftUI
import Combine

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct MainView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var pendingAlbumProcessor = PendingAlbumProcessor.shared
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedFeed: Feed = .obi
    @State private var showSearch = false
    @State private var bottomSpacerHeight: CGFloat = 100
    @State private var showProfile = false
    @State private var showMenu = false
    @State private var showCreateList = false
    @State private var showCreateAlbum = false
    @State private var showSearchSheet = false
    @State private var isAddButtonPressed = false
    @State private var searchText = ""
    @State private var buttonTransitionProgress: CGFloat = 0.0 // ボタン変形用の進行度
    @State private var scrollPosition: Int? = 0 // ScrollViewの位置
    @State private var showAddAlbumSheet = false
    @Namespace private var animation

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
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // ヘッダー（横並びタブ + プロフィール）
                    HStack(spacing: 0) {
                        // 横並びタブ
                        HorizontalTabBar(selectedFeed: $selectedFeed, scrollPosition: $scrollPosition)

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

                    // コンテンツ表示エリア
                    pagingScrollView
                }
                .ignoresSafeArea(edges: .bottom)

                // 背景オーバーレイ（メニュー表示時）
                if showMenu {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                showMenu = false
                            }
                        }
                }

                // 下部ボタンエリア
                bottomButtons
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileView(authViewModel: authViewModel)
                }
            }
            .sheet(isPresented: $showCreateList) {
                CreateListView()
            }
            .sheet(isPresented: $showCreateAlbum) {
                CreateAlbumView()
            }
            .sheet(isPresented: $showSearchSheet) {
                SearchView()
            }
        }
    }

    private var pagingScrollView: some View {
        GeometryReader { geometry in
            scrollViewContent(geometry: geometry)
        }
    }

    private func scrollViewContent(geometry: GeometryProxy) -> some View {
        let pageWidth = geometry.size.width
        let bottomPadding = calculateBottomPadding(safeAreaBottom: geometry.safeAreaInsets.bottom)

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ObiView(bottomSpacerHeight: bottomSpacerHeight)
                    .containerRelativeFrame(.horizontal)
                    .id(0)

                HomeView(bottomSpacerHeight: bottomSpacerHeight)
                    .containerRelativeFrame(.horizontal)
                    .id(1)
            }
            .scrollTargetLayout()
            .background(
                GeometryReader { scrollGeo in
                    Color.clear
                        .onChange(of: scrollGeo.frame(in: .global).minX) { _, minX in
                            // HStack全体の座標からprogressを計算
                            let progress = -minX / pageWidth
                            let clampedProgress = max(0.0, min(1.0, progress))
                            buttonTransitionProgress = clampedProgress
                            print("📊 HStack minX: \(minX), progress: \(clampedProgress)")
                        }
                }
            )
        }
        .scrollPosition(id: $scrollPosition)
        .scrollTargetBehavior(PagingScrollTargetBehavior())
        .ignoresSafeArea()
        .padding(EdgeInsets(top: 0, leading: 0, bottom: bottomPadding, trailing: 0))
        .onChange(of: scrollPosition) { _, newValue in
            updateFeedFromScroll(newValue)
        }
        .onChange(of: selectedFeed) { _, newValue in
            updateScrollFromFeed(newValue)
        }
        .onAppear {
            setupInitialState(bottomPadding: bottomPadding)
        }
        .sheet(isPresented: $showAddAlbumSheet) {
            if let pendingMusic = deepLinkManager.pendingMusic {
                AddAlbumFromShareView(musicId: pendingMusic.id, musicType: pendingMusic.type)
                    .onDisappear {
                        deepLinkManager.clearPendingMusic()
                    }
            }
        }
        .onChange(of: deepLinkManager.pendingMusic) { oldValue, newValue in
            if newValue != nil {
                showAddAlbumSheet = true
            }
        }
    }

    private func updateProgressFromScroll(minX: CGFloat, pageWidth: CGFloat) {
        // 中央からのズレを計算（0なら中央、-1なら次のページ）
        let progress = -minX / pageWidth
        let clampedProgress = max(0.0, min(1.0, progress))

        print("📊 minX: \(minX), progress: \(clampedProgress)")

        // アニメーションなしで即座に反映（スワイプに追従）
        buttonTransitionProgress = clampedProgress
    }

    private func updateProgress(offset: CGFloat, pageWidth: CGFloat) {
        let progress = -offset / pageWidth
        let clampedProgress = max(0.0, min(1.0, progress))
        print("📊 offset: \(offset), width: \(pageWidth), progress: \(clampedProgress)")
        buttonTransitionProgress = clampedProgress
    }

    private func updateFeedFromScroll(_ position: Int?) {
        guard let position = position else { return }
        selectedFeed = position == 0 ? .obi : .explore
    }

    private func updateScrollFromFeed(_ feed: Feed) {
        scrollPosition = feed == .obi ? 0 : 1
    }

    private func setupInitialState(bottomPadding: CGFloat) {
        bottomSpacerHeight = abs(bottomPadding)
        scrollPosition = selectedFeed == .explore ? 1 : 0
        buttonTransitionProgress = selectedFeed == .explore ? 1.0 : 0.0
    }

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack(alignment: .bottom, spacing: 8) {
                // 左側: Addボタン / メニュー
                ZStack {
                    // メニューコンテンツ（Obiタブでメニュー表示時）
                    if showMenu && selectedFeed == .obi {
                        VStack(spacing: 0) {
                            // レビューボタン
                            Button(action: {
                                showMenu = false
                                showSearchSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "star.bubble")
                                        .font(.title3)
                                    Text("レビュー")
                                        .font(.headline)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 24)
                            }
                            .buttonStyle(ScaleButtonStyle())

                            Divider()
                                .background(Color.white.opacity(0.2))

                            // リストボタン
                            Button(action: {
                                showMenu = false
                                showCreateList = true
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle")
                                        .font(.title3)
                                    Text("リスト")
                                        .font(.headline)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 24)
                            }
                            .buttonStyle(ScaleButtonStyle())

                            Divider()
                                .background(Color.white.opacity(0.2))

                            // アルバムボタン
                            Button(action: {
                                showMenu = false
                                showCreateAlbum = true
                            }) {
                                HStack {
                                    Image(systemName: "square.stack.3d.up")
                                        .font(.title3)
                                    Text("アルバム")
                                        .font(.headline)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 24)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .transition(.opacity)
                    }

                    // Addボタン（メニュー非表示時）
                    if !showMenu {
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                showMenu = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)

                                // "Add"テキスト: progressが進むとフェードアウト
                                if buttonTransitionProgress < 0.8 {
                                    Text("Add")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .opacity(Double(1.0 - min(buttonTransitionProgress / 0.8, 1.0)))
                                }
                            }
                            // パディング: progressに応じて縮小
                            .padding(.vertical, 16 - buttonTransitionProgress * 2)
                            .padding(.horizontal, 32 - buttonTransitionProgress * 18)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isAddButtonPressed {
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            isAddButtonPressed = true
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        isAddButtonPressed = false
                                    }
                                }
                        )
                        .scaleEffect(isAddButtonPressed ? 0.95 : 1.0)
                        .transition(.opacity)
                    }
                }
                .background(colorScheme == .dark ? Color(uiColor: .darkGray) : Color.black)
                .cornerRadius(showMenu ? 16 : (30 - buttonTransitionProgress * 6))
                .shadow(color: .black.opacity(showMenu ? 0 : 0.3), radius: 10, x: 0, y: 5)
                .animation(.spring(response: 0.25, dampingFraction: 0.85), value: showMenu)

                Spacer()

                // 右側: 検索ボタン → 検索フィールド（progressに応じて変化）
                Button(action: {
                    if buttonTransitionProgress < 0.5 {
                        // メニューが開いていたら閉じる
                        if showMenu {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                showMenu = false
                            }
                            // メニューが閉じるのを待ってからスクロール
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    scrollPosition = 1
                                }
                            }
                        } else {
                            // ScrollViewをスクロールさせてExploreに移動
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                scrollPosition = 1
                            }
                        }
                    }
                }) {
                    HStack(spacing: 12 * buttonTransitionProgress) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        // テキストフィールド: 常に存在するがopacityと幅で制御
                        TextField("検索", text: $searchText)
                            .foregroundColor(.white)
                            .font(.body)
                            .accentColor(.white)
                            .opacity(Double(max((buttonTransitionProgress - 0.2) / 0.8, 0.0)))
                            .frame(width: max(0, (ScreenMetrics.shared.screenWidth-48-16-96) * (buttonTransitionProgress - 0.1)))
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 14 )
                }
                .buttonStyle(PlainButtonStyle())
                .allowsHitTesting(buttonTransitionProgress < 0.5)
                .background(colorScheme == .dark ? Color(uiColor: .darkGray) : Color.black)
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 0)
        }
    }
}

// MARK: - Feed Type
enum Feed: String, CaseIterable {
    case obi = "Obi"
    case explore = "Explore"
}

// MARK: - Horizontal Tab Bar
struct HorizontalTabBar: View {
    @Binding var selectedFeed: Feed
    @Binding var scrollPosition: Int?

    var body: some View {
        HStack(spacing: 24) {
            ForEach(Feed.allCases, id: \.self) { feed in
                Button(action: {
                    // スクロールアニメーションで切り替え
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scrollPosition = feed == .obi ? 0 : 1
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
        .padding(.horizontal, 24)
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

    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // 上部の正方形グレー背景エリア（ObiCard表示エリア）
                    GeometryReader { geometry in
                        NavigationLink(destination: ObiListView()) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: geometry.size.width, height: geometry.size.width)
                                .overlay(
                                    // ObiCardを中央に配置
                                    Group {
                                        if let review = viewModel.latestReview {
                                            ObiCard(
                                                artworkURL: review.albumArt,
                                                reviewTitle: review.reviewTitle ?? review.title,
                                                reviewText: review.text ?? "レビューテキストがありません",
                                                cardHeight: geometry.size.width - 24,
                                                style: ObiCardStyle.forTargetType(review.targetType),
                                                rating: review.rating
                                            )
                                        } else {
                                            // レビューがない場合はプレースホルダー
                                            VStack(spacing: 16) {
                                                Image(systemName: "music.note.list")
                                                    .font(.system(size: 48))
                                                    .foregroundColor(.gray.opacity(0.5))
                                                Text("レビューを書いてみましょう")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        // デフォルトリスト + カスタムリスト + ユーザーアルバム（統一された2列グリッド）
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                            // デフォルトリスト
                            NavigationLink(destination: ListDetailView(listType: .reviewed)) {
                                ListCard(
                                    title: "レビュー済み",
                                    count: viewModel.reviewedCount,
                                    artworkURLs: viewModel.reviewedArtworks
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: ListDetailView(listType: .favorite)) {
                                ListCard(
                                    title: "お気に入り",
                                    count: viewModel.favoriteCount,
                                    artworkURLs: viewModel.favoriteArtworks
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: ListDetailView(listType: .listened)) {
                                ListCard(
                                    title: "聴いた",
                                    count: viewModel.listenedCount,
                                    artworkURLs: viewModel.listenedArtworks
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: ListDetailView(listType: .wishlist)) {
                                ListCard(
                                    title: "聴きたい",
                                    count: viewModel.wishlistCount,
                                    artworkURLs: viewModel.wishlistArtworks
                                )
                            }
                            .buttonStyle(.plain)

                            // カスタムリスト + ユーザーアルバム
                            ForEach(viewModel.obiItems) { item in
                                switch item {
                                case .list(let list):
                                    NavigationLink(destination: CustomListDetailView(list: list)) {
                                        ListCard(
                                            title: list.name,
                                            count: viewModel.customListCounts[list.id] ?? 0,
                                            artworkURLs: viewModel.customListArtworks[list.id] ?? []
                                        )
                                    }
                                    .buttonStyle(.plain)

                                case .userAlbum(let album):
                                    NavigationLink(destination: UserAlbumDetailView(album: album)) {
                                        AlbumCard(
                                            title: album.name,
                                            artistName: album.artistName,
                                            colorHex: album.colorHex
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                          .padding(.top, 16)
                    }

                    // TabViewの下部拡張分のスペーサー
                    Color.clear
                        .frame(height: 120)
                }
            }
            .task {
                await viewModel.loadListCounts()
            }
            .refreshable {
                await viewModel.loadListCounts()
            }
    }
}

// MARK: - Custom List Detail View
struct CustomListDetailView: View {
    let list: MusicList
    @StateObject private var viewModel: CustomListDetailViewModel
    @State private var showingSearchSheet = false

    init(list: MusicList) {
        self.list = list
        self._viewModel = StateObject(wrappedValue: CustomListDetailViewModel(listId: list.id))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if viewModel.albums.isEmpty {
                    ContentUnavailableView(
                        "アルバムがありません",
                        systemImage: "music.note",
                        description: Text("アルバムを追加してみましょう")
                    )
                    .padding(.vertical, 40)
                } else {
                    // 3列グリッド（画像のみ）
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(viewModel.albums) { album in
                            NavigationLink(destination: AlbumDetailView(album: album)) {
                                AlbumGridItem(album: album)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                }
            }

            // フローティングアクションボタン
            Button(action: {
                showingSearchSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.purple)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSearchSheet) {
            SearchView()
        }
        .task {
            await viewModel.loadAlbums()
        }
        .refreshable {
            await viewModel.loadAlbums()
        }
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
