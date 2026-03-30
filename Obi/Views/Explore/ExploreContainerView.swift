//
//  ExploreContainerView.swift
//  Obi
//
//  Exploreタブのコンテナビュー（PageViewController統合）
//

import SwiftUI

struct ExploreContainerView: View, Equatable {
    let bottomSpacerHeight: CGFloat
    @ObservedObject var pageManager: ExplorePageManager

    init(bottomSpacerHeight: CGFloat, pageManager: ExplorePageManager) {
        self.bottomSpacerHeight = bottomSpacerHeight
        self.pageManager = pageManager
        print("🏗️ ExploreContainerView init - pages: \(pageManager.pages.count), currentIndex: \(pageManager.currentIndex)")
    }

    static func == (lhs: ExploreContainerView, rhs: ExploreContainerView) -> Bool {
        // ObservedObjectは参照比較なので、同じインスタンスかどうかだけチェック
        lhs.bottomSpacerHeight == rhs.bottomSpacerHeight &&
        lhs.pageManager === rhs.pageManager
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
    private func pageView(for content: ExplorePageContent) -> some View {
        switch content {
        case .feed:
            HomeView(
                bottomSpacerHeight: bottomSpacerHeight,
                onNavigate: { destination in
                    pageManager.navigateTo(destination)
                }
            )

        case .albumDetail(let album):
            AlbumDetailView(album: album)
                .navigationBarHidden(true)

        case .trackDetail(let track):
            TrackDetailView(track: track)
                .navigationBarHidden(true)

        case .reviewDetail(let reviewWithUser):
            ReviewDetailView(review: reviewWithUser.review)
                .navigationBarHidden(true)
        }
    }
}
