//
//  ObiContainerView.swift
//  Obi
//
//  Obiタブのコンテナビュー（PageViewController統合）
//

import SwiftUI

struct ObiContainerView: View, Equatable {
    let bottomSpacerHeight: CGFloat
    @ObservedObject var pageManager: ObiPageManager
    @ObservedObject var listViewModel: ObiListViewModel

    init(bottomSpacerHeight: CGFloat, pageManager: ObiPageManager, listViewModel: ObiListViewModel) {
        self.bottomSpacerHeight = bottomSpacerHeight
        self.pageManager = pageManager
        self.listViewModel = listViewModel
        print("🏗️ ObiContainerView init - pages: \(pageManager.pages.count), currentIndex: \(pageManager.currentIndex)")
    }

    static func == (lhs: ObiContainerView, rhs: ObiContainerView) -> Bool {
        // ObservedObjectは参照比較なので、同じインスタンスかどうかだけチェック
        lhs.bottomSpacerHeight == rhs.bottomSpacerHeight &&
        lhs.pageManager === rhs.pageManager &&
        lhs.listViewModel === rhs.listViewModel
    }

    var body: some View {
        PageViewController(
            pages: pageManager.pages.map { pageContent in
                AnyView(pageView(for: pageContent))
            },
            pageIds: pageManager.pages.map { $0.id },
            currentIndex: $pageManager.currentIndex,
            onPageChange: { index in
                pageManager.handlePageChange(to: index)
            }
        )
    }

    @ViewBuilder
    private func pageView(for content: ObiPageContent) -> some View {
        switch content {
        case .cardList:
            ObiCardListView(
                viewModel: listViewModel,
                bottomSpacerHeight: bottomSpacerHeight,
                onNavigate: { destination in
                    pageManager.navigateTo(destination)
                }
            )

        case .defaultList(let category):
            ListDetailView(listType: category)
                .navigationBarHidden(true)

        case .customList(let list):
            CustomListDetailView(list: list)
                .navigationBarHidden(true)

        case .userAlbum(let album):
            UserAlbumDetailView(album: album)
                .navigationBarHidden(true)
        }
    }
}

// MARK: - Card List View
struct ObiCardListView: View {
    @ObservedObject var viewModel: ObiListViewModel
    let bottomSpacerHeight: CGFloat
    let onNavigate: (ObiPageContent) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // ObiCard表示エリア
                GeometryReader { geometry in
                    NavigationLink(destination: ObiListView()) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .overlay(
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
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                        // デフォルトリスト
                        Button(action: { onNavigate(.defaultList(.reviewed)) }) {
                            ListCard(
                                title: "レビュー済み",
                                count: viewModel.reviewedCount,
                                artworkURLs: viewModel.reviewedArtworks
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: { onNavigate(.defaultList(.favorite)) }) {
                            ListCard(
                                title: "お気に入り",
                                count: viewModel.favoriteCount,
                                artworkURLs: viewModel.favoriteArtworks
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: { onNavigate(.defaultList(.listened)) }) {
                            ListCard(
                                title: "聴いた",
                                count: viewModel.listenedCount,
                                artworkURLs: viewModel.listenedArtworks
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: { onNavigate(.defaultList(.wishlist)) }) {
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
                                Button(action: { onNavigate(.customList(list)) }) {
                                    ListCard(
                                        title: list.name,
                                        count: viewModel.customListCounts[list.id] ?? 0,
                                        artworkURLs: viewModel.customListArtworks[list.id] ?? []
                                    )
                                }
                                .buttonStyle(.plain)

                            case .userAlbum(let album):
                                Button(action: { onNavigate(.userAlbum(album)) }) {
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

                Color.clear
                    .frame(height: 120)
            }
        }
        .refreshable {
            await viewModel.loadListCounts()
        }
    }
}
