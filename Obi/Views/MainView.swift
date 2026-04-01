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
    @StateObject private var searchHistoryViewModel = SearchHistoryViewModel()
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
    @State private var showCreateReview = false
    @State private var isAddButtonPressed = false
    @State private var searchText = ""
    @State private var buttonTransitionProgress: CGFloat = 0.0 // ボタン変形用の進行度
    @State private var scrollPosition: Int? = 0 // ScrollViewの位置
    @State private var showAddAlbumSheet = false
    @FocusState private var isSearchFieldFocused: Bool
    @Namespace private var animation

    // Obiページ管理
    @StateObject private var obiPageManager = ObiPageManager()
    @StateObject private var obiListViewModel = ObiListViewModel()

    // Exploreページ管理
    @StateObject private var explorePageManager = ExplorePageManager()

    // 新規作成されたアルバム/リストへのナビゲーション用
    @State private var createdUserAlbum: UserAlbum?
    @State private var createdList: MusicList?
    @State private var navigateToNewUserAlbum = false
    @State private var navigateToNewList = false

    // カスタムリスト/ユーザーアルバムのタイトル編集用
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    @FocusState private var isTitleFieldFocused: Bool

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
                    // 動的ヘッダー
                    dynamicHeader
                        .animation(.easeInOut(duration: 0.2), value: obiPageManager.currentPage.id)
                        .animation(.easeInOut(duration: 0.2), value: explorePageManager.currentPage.id)
                        .animation(.easeInOut(duration: 0.2), value: selectedFeed)

                    Divider()

                    // コンテンツ表示エリア
                    pagingScrollView
                }
                .ignoresSafeArea(edges: .bottom)
                .onChange(of: obiPageManager.currentPage.id) { _, _ in
                    // ページ遷移時に編集モードを解除
                    if isEditingTitle {
                        isEditingTitle = false
                        isTitleFieldFocused = false
                    }
                }
                .onTapGesture {
                    // コンテンツエリアタップでフォーカスを外す
                    if isEditingTitle {
                        isEditingTitle = false
                        isTitleFieldFocused = false
                    }
                    if isSearchFieldFocused {
                        isSearchFieldFocused = false
                    }
                }

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

                // 検索履歴オーバーレイ（フォーカス時）
                if isSearchFieldFocused {
                    SearchHistoryOverlay(
                        viewModel: searchHistoryViewModel,
                        searchText: $searchText,
                        onSelectSearch: { query in
                            searchText = query
                            searchHistoryViewModel.addSearch(query)
                            isSearchFieldFocused = false
                        }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
                    .ignoresSafeArea(edges: .bottom)
                }

                // 下部ボタンエリア（ルート画面とリスト詳細のみ表示）
                let isObiRoot = obiPageManager.currentPage.id == "cardList"
                let isObiListDetail: Bool = {
                    switch obiPageManager.currentPage {
                    case .defaultList, .customList:
                        return true
                    default:
                        return false
                    }
                }()
                let isExploreRoot = explorePageManager.currentPage.id == "feed"
                let shouldShowButtons = (selectedFeed == .obi && (isObiRoot || isObiListDetail)) || (selectedFeed == .explore && isExploreRoot)

                // 検索ボタン表示条件: Obiカードリストまたは、ExploreのFeed画面のみ
                let shouldShowSearchButton = (selectedFeed == .obi && isObiRoot) || (selectedFeed == .explore && isExploreRoot)

                if shouldShowButtons {
                    bottomButtons(showSearchButton: shouldShowSearchButton)
                }
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
            .sheet(isPresented: $showCreateReview) {
                NavigationStack {
                    WriteReviewView(musicItem: MusicItem(
                        id: "",
                        title: "対象を選択してください",
                        artist: "",
                        artworkURL: nil,
                        type: .album
                    ))
                }
            }
            .background(
                Group {
                    // 新規作成されたリストへのナビゲーション
                    if let list = createdList {
                        NavigationLink(
                            destination: CustomListDetailView(list: list),
                            isActive: $navigateToNewList
                        ) {
                            EmptyView()
                        }
                    }

                    // 新規作成されたアルバムへのナビゲーション
                    if let album = createdUserAlbum {
                        NavigationLink(
                            destination: UserAlbumDetailView(album: album),
                            isActive: $navigateToNewUserAlbum
                        ) {
                            EmptyView()
                        }
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var dynamicHeader: some View {
        HStack(spacing: 0) {
            let isObiRoot = obiPageManager.currentPage.id == "cardList"
            let isExploreRoot = explorePageManager.currentPage.id == "feed"

            if (selectedFeed == .obi && isObiRoot) || (selectedFeed == .explore && isExploreRoot) {
                // Obi一覧またはExploreフィード: 横並びタブ
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
                .padding(.trailing, 24)
            } else {
                // 詳細ページ: 戻るボタン (+ タイトル)
                Button(action: {
                    if selectedFeed == .obi {
                        obiPageManager.goBack()
                    } else {
                        explorePageManager.goBack()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .padding(.leading, 24)

                Spacer()

                // リスト詳細の場合のみタイトル表示（userAlbum/albumDetail/trackDetailは各View内で表示）
                if selectedFeed == .obi {
                    switch obiPageManager.currentPage {
                    case .defaultList(let category):
                        Text(category.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                    case .customList(let list):
                        if isEditingTitle {
                            TextField("タイトルなし", text: $editedTitle)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .focused($isTitleFieldFocused)
                                .onSubmit {
                                    Task {
                                        await updateListTitle(list: list)
                                    }
                                }
                        } else {
                            Text(list.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .onTapGesture {
                                    editedTitle = list.name
                                    isEditingTitle = true
                                    isTitleFieldFocused = true
                                }
                        }
                    default:
                        EmptyView()
                    }
                }

                Spacer()

                // 詳細ページの場合メニューボタン表示
                if selectedFeed == .obi {
                    switch obiPageManager.currentPage {
                    case .defaultList, .customList, .userAlbum, .albumDetail, .trackDetail:
                        Menu {
                            Button(action: {
                                // TODO: 編集機能
                            }) {
                                Label("編集", systemImage: "pencil")
                            }

                            // カスタム系のみ削除オプションを表示
                            switch obiPageManager.currentPage {
                            case .customList, .userAlbum:
                                Divider()

                                Button(role: .destructive, action: {
                                    // TODO: 削除機能
                                }) {
                                    Label("削除", systemImage: "trash")
                                }
                            default:
                                EmptyView()
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.trailing, 24)
                    default:
                        // 右側のスペース（一貫性のため確保）
                        Color.clear
                            .frame(width: 44)
                            .padding(.trailing, 24)
                    }
                } else if selectedFeed == .explore {
                    switch explorePageManager.currentPage {
                    case .albumDetail, .trackDetail, .reviewDetail:
                        Menu {
                            Button(action: {
                                // TODO: 編集機能
                            }) {
                                Label("編集", systemImage: "pencil")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.trailing, 24)
                    default:
                        // 右側のスペース（一貫性のため確保）
                        Color.clear
                            .frame(width: 44)
                            .padding(.trailing, 24)
                    }
                } else {
                    // 右側のスペース（一貫性のため確保）
                    Color.clear
                        .frame(width: 44)
                        .padding(.trailing, 24)
                }
            }
        }
        .frame(height: 44)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.background)
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
                ObiContainerView(bottomSpacerHeight: bottomSpacerHeight, pageManager: obiPageManager, listViewModel: obiListViewModel)
                    .equatable()
                    .containerRelativeFrame(.horizontal)
                    .id(0)

                ExploreContainerView(bottomSpacerHeight: bottomSpacerHeight, pageManager: explorePageManager)
                    .equatable()
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
        .task {
            await obiListViewModel.loadListCounts()
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
        print("🚀 MainView setupInitialState - selectedFeed: \(selectedFeed), obiPageManager.pages: \(obiPageManager.pages.count), currentIndex: \(obiPageManager.currentIndex)")
        bottomSpacerHeight = abs(bottomPadding)
        scrollPosition = selectedFeed == .explore ? 1 : 0
        buttonTransitionProgress = selectedFeed == .explore ? 1.0 : 0.0
    }

    @ViewBuilder
    private func bottomButtons(showSearchButton: Bool) -> some View {
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
                                showCreateReview = true
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
                                Task {
                                    await createNewList()
                                }
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
                                Task {
                                    await createNewAlbum()
                                }
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

                    // Addボタン / キャンセルボタン（メニュー非表示時）
                    if !showMenu {
                        Button(action: {
                            if isSearchFieldFocused {
                                // フォーカス中: キャンセル（フォーカスを外す）
                                isSearchFieldFocused = false
                            } else {
                                // フォーカスなし: メニューを開く
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                    showMenu = true
                                }
                            }
                        }) {
                            HStack(spacing: 8 * (1.0 - buttonTransitionProgress)) {
                                Image(systemName: isSearchFieldFocused ? "xmark" : "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(isSearchFieldFocused ? 90 : 0))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearchFieldFocused)

                                // "Add"テキスト: 常に存在するが幅とopacityで制御
                                Text("Add")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .opacity(Double(1.0 - min(buttonTransitionProgress / 0.8, 1.0)))
                                    .frame(width: max(0, 35 * (1.0 - buttonTransitionProgress / 0.8)))
                                    .clipped()
                            }
                            // パディング: progressに応じて縮小（円形を保つため同じ値に）
                            .padding(.vertical, max(14, 16 - buttonTransitionProgress * 2))
                            .padding(.horizontal, max(14, 32 - buttonTransitionProgress * 18))
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
                .cornerRadius(showMenu ? 16 : max(24, 30 - buttonTransitionProgress * 12))
                .shadow(color: .black.opacity(showMenu ? 0 : 0.3), radius: 10, x: 0, y: 5)
                .animation(.spring(response: 0.25, dampingFraction: 0.85), value: showMenu)

                Spacer()

                // 右側: 検索ボタン → 検索フィールド（progressに応じて変化）
                if showSearchButton {
                    ZStack {
                        // Obiビューの時: ボタンとして動作（Exploreに移動）
                        if buttonTransitionProgress < 0.5 {
                            Button(action: {
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
                                        .disabled(true)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 14)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // Exploreビューの時: TextFieldとして動作（タップでフォーカス）
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
                                    .focused($isSearchFieldFocused)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 14)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isSearchFieldFocused = true
                            }
                        }
                    }
                    .background(colorScheme == .dark ? Color(uiColor: .darkGray) : Color.black)
                    .cornerRadius(30)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 0)
        }
    }

    // MARK: - Helper Methods

    /// カスタムリストのタイトルを更新
    private func updateListTitle(list: MusicList) async {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? "タイトルなし" : trimmedTitle

        guard finalTitle != list.name else {
            isEditingTitle = false
            isTitleFieldFocused = false
            return
        }

        do {
            try await SupabaseService.shared.updateList(
                listId: list.id,
                name: finalTitle,
                description: nil,
                isPublic: nil
            )
            print("✅ [MainView] List title updated: \(finalTitle)")

            // ページマネージャーのページを更新
            if case .customList(var updatedList) = obiPageManager.currentPage {
                updatedList = MusicList(
                    id: updatedList.id,
                    userId: updatedList.userId,
                    name: finalTitle,
                    description: updatedList.description,
                    isPublic: updatedList.isPublic,
                    type: updatedList.type,
                    defaultType: updatedList.defaultType,
                    createdAt: updatedList.createdAt,
                    parentListId: updatedList.parentListId
                )
                obiPageManager.updateCurrentPage(.customList(updatedList))
            }

            isEditingTitle = false
            isTitleFieldFocused = false

            // リストビューを再読み込み
            await obiListViewModel.loadListCounts()
        } catch {
            print("❌ [MainView] Failed to update list title: \(error)")
            isEditingTitle = false
            isTitleFieldFocused = false
        }
    }

    /// ユーザーアルバムのタイトルを更新
    private func updateUserAlbumTitle(album: UserAlbum) async {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? "タイトルなし" : trimmedTitle

        guard finalTitle != album.name else {
            isEditingTitle = false
            isTitleFieldFocused = false
            return
        }

        do {
            try await SupabaseService.shared.updateUserAlbum(
                albumId: album.id,
                name: finalTitle,
                colorHex: nil
            )
            print("✅ [MainView] User album title updated: \(finalTitle)")

            // ページマネージャーのページを更新
            if case .userAlbum(var updatedAlbum) = obiPageManager.currentPage {
                updatedAlbum = UserAlbum(
                    id: updatedAlbum.id,
                    userId: updatedAlbum.userId,
                    name: finalTitle,
                    artistName: updatedAlbum.artistName,
                    colorHex: updatedAlbum.colorHex,
                    createdAt: updatedAlbum.createdAt,
                    updatedAt: Date()
                )
                obiPageManager.updateCurrentPage(.userAlbum(updatedAlbum))
            }

            isEditingTitle = false
            isTitleFieldFocused = false

            // リストビューを再読み込み
            await obiListViewModel.loadListCounts()
        } catch {
            print("❌ [MainView] Failed to update user album title: \(error)")
            isEditingTitle = false
            isTitleFieldFocused = false
        }
    }

    /// 新しいリストを「タイトルなし」で即座に作成
    private func createNewList() async {
        guard let userId = UserManager.shared.currentUserId else {
            print("❌ User not authenticated")
            return
        }

        // 親リストIDを取得（現在表示中のリスト詳細画面がある場合）
        // デフォルトリストは親として設定しない（親子関係は不要）
        var parentListId: UUID? = nil
        print("🔍 [createNewList] selectedFeed: \(selectedFeed)")
        print("🔍 [createNewList] currentPage: \(obiPageManager.currentPage.id)")
        if selectedFeed == .obi {
            switch obiPageManager.currentPage {
            case .customList(let list):
                parentListId = list.id
                print("✅ [createNewList] Found parent list: \(list.name) (id: \(list.id))")
            default:
                print("ℹ️ [createNewList] Not in customList page")
                break
            }
        }
        print("🔍 [createNewList] parentListId: \(String(describing: parentListId))")

        do {
            let newList = MusicList(
                id: UUID(),
                userId: userId,
                name: "タイトルなし",
                description: nil,
                isPublic: false,
                type: .custom,
                defaultType: nil,
                createdAt: Date(),
                parentListId: parentListId
            )

            let createdList = try await SupabaseService.shared.createList(newList, parentListId: parentListId)

            if let parentId = parentListId {
                print("✅ [MainView] List created as child: \(createdList.name), parent: \(parentId)")
            } else {
                print("✅ [MainView] List created: \(createdList.name)")
            }

            // 作成されたリストへナビゲート
            self.createdList = createdList
            self.navigateToNewList = true
        } catch {
            print("❌ [MainView] Failed to create list: \(error)")
        }
    }

    /// 新しいアルバムを「タイトルなし」で即座に作成
    private func createNewAlbum() async {
        guard let userId = UserManager.shared.currentUserId else {
            print("❌ User not authenticated")
            return
        }

        // 親リストIDを取得（現在表示中のリスト詳細画面がある場合）
        // デフォルトリストは親として設定しない（親子関係は不要）
        var parentListId: String? = nil
        print("🔍 [createNewAlbum] selectedFeed: \(selectedFeed)")
        print("🔍 [createNewAlbum] currentPage: \(obiPageManager.currentPage.id)")
        if selectedFeed == .obi {
            switch obiPageManager.currentPage {
            case .customList(let list):
                parentListId = list.id.uuidString
                print("✅ [createNewAlbum] Found parent list: \(list.name) (id: \(list.id))")
            default:
                print("ℹ️ [createNewAlbum] Not in customList page")
                break
            }
        }
        print("🔍 [createNewAlbum] parentListId: \(String(describing: parentListId))")

        do {
            let artistName = UserManager.shared.displayName
            let createdAlbum = try await SupabaseService.shared.createUserAlbum(
                userId: userId.uuidString,
                name: "タイトルなし",
                artistName: artistName,
                colorHex: "#9F7AEA", // デフォルトのパープル
                parentListId: parentListId
            )

            if let parentId = parentListId {
                print("✅ [MainView] Album created as child: \(createdAlbum.name), parent: \(parentId)")
            } else {
                print("✅ [MainView] Album created: \(createdAlbum.name)")
            }

            // 作成されたアルバムへナビゲート
            self.createdUserAlbum = createdAlbum
            self.navigateToNewUserAlbum = true
        } catch {
            print("❌ [MainView] Failed to create album: \(error)")
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

// MARK: - Custom List Detail View
struct CustomListDetailView: View {
    let list: MusicList
    var onNavigateToAlbum: ((Album) -> Void)? = nil
    var onNavigateToList: ((MusicList) -> Void)? = nil
    var onNavigateToUserAlbum: ((UserAlbum) -> Void)? = nil
    @StateObject private var viewModel: CustomListDetailViewModel
    @State private var showingSearchSheet = false
    @State private var editedName: String
    @State private var isEditingName = false
    @FocusState private var isNameFieldFocused: Bool

    init(list: MusicList, onNavigateToAlbum: ((Album) -> Void)? = nil, onNavigateToList: ((MusicList) -> Void)? = nil, onNavigateToUserAlbum: ((UserAlbum) -> Void)? = nil) {
        self.list = list
        self.onNavigateToAlbum = onNavigateToAlbum
        self.onNavigateToList = onNavigateToList
        self.onNavigateToUserAlbum = onNavigateToUserAlbum
        self._viewModel = StateObject(wrappedValue: CustomListDetailViewModel(listId: list.id))
        self._editedName = State(initialValue: list.name)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    // 子リスト/アルバムセクション（存在する場合のみ表示）
                    if !viewModel.childLists.isEmpty || !viewModel.childUserAlbums.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20)
                        ], spacing: 20) {
                            // 子カスタムリスト
                            ForEach(viewModel.childLists) { childList in
                                Button(action: {
                                    onNavigateToList?(childList)
                                }) {
                                    ListCard(
                                        title: childList.name,
                                        count: 0,
                                        artworkURLs: []
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            // 子ユーザーアルバム
                            ForEach(viewModel.childUserAlbums) { childAlbum in
                                Button(action: {
                                    onNavigateToUserAlbum?(childAlbum)
                                }) {
                                    AlbumCard(
                                        title: childAlbum.name,
                                        artistName: childAlbum.artistName,
                                        colorHex: childAlbum.colorHex
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                    }

                    // 音楽アルバムセクション
                    if viewModel.albums.isEmpty && viewModel.childLists.isEmpty && viewModel.childUserAlbums.isEmpty {
                        ContentUnavailableView(
                            "アイテムがありません",
                            systemImage: "music.note",
                            description: Text("アルバムやリストを追加してみましょう")
                        )
                        .padding(.vertical, 40)
                    } else if !viewModel.albums.isEmpty {
                        // 2列グリッド（画像のみ）
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(viewModel.albums) { album in
                                if let onNavigate = onNavigateToAlbum {
                                    Button(action: {
                                        onNavigate(album)
                                    }) {
                                        AlbumGridItem(album: album)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink(destination: AlbumDetailView(album: album)) {
                                        AlbumGridItem(album: album)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, viewModel.childLists.isEmpty && viewModel.childUserAlbums.isEmpty ? 40 : 20)
                    }
                }

                Color.clear.frame(height: 120)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if isEditingName {
                    TextField("タイトルなし", text: $editedName)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .focused($isNameFieldFocused)
                        .onSubmit {
                            Task {
                                await updateListName()
                            }
                        }
                } else {
                    Button(action: {
                        isEditingName = true
                        isNameFieldFocused = true
                    }) {
                        Text(editedName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        isEditingName = true
                        isNameFieldFocused = true
                    }) {
                        Label("名前を変更", systemImage: "pencil")
                    }

                    Button(action: {
                        // TODO: 説明編集機能
                    }) {
                        Label("説明を編集", systemImage: "text.alignleft")
                    }

                    Button(action: {
                        // TODO: 公開設定機能
                    }) {
                        Label("公開設定", systemImage: "eye")
                    }

                    Divider()

                    Button(role: .destructive, action: {
                        // TODO: 削除機能
                    }) {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchView(filter: .albumsOnly, listId: list.id)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
        .task {
            await viewModel.loadAlbums()
        }
    }

    // MARK: - Helper Methods

    private func updateListName() async {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 空の場合は「タイトルなし」として保存
        let finalName = trimmedName.isEmpty ? "タイトルなし" : trimmedName

        guard finalName != list.name else {
            editedName = list.name
            isEditingName = false
            return
        }

        do {
            try await SupabaseService.shared.updateList(
                listId: list.id,
                name: finalName,
                description: nil,
                isPublic: nil
            )
            print("✅ [CustomListDetailView] List name updated: \(finalName)")
            editedName = finalName
            isEditingName = false
        } catch {
            print("❌ [CustomListDetailView] Failed to update list name: \(error)")
            editedName = list.name
            isEditingName = false
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
