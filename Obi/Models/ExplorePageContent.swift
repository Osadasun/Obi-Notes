//
//  ExplorePageContent.swift
//  Obi
//
//  Exploreページのコンテンツタイプ定義
//

import Foundation

enum ExplorePageContent: Identifiable, Equatable {
    case feed
    case albumDetail(Album)
    case trackDetail(Track)
    case reviewDetail(ReviewWithUser)

    var id: String {
        switch self {
        case .feed:
            return "feed"
        case .albumDetail(let album):
            return "albumDetail_\(album.id)"
        case .trackDetail(let track):
            return "trackDetail_\(track.id)"
        case .reviewDetail(let reviewWithUser):
            return "reviewDetail_\(reviewWithUser.review.id)"
        }
    }

    var title: String {
        switch self {
        case .feed:
            return "Explore"
        case .albumDetail(let album):
            return album.title
        case .trackDetail(let track):
            return track.title
        case .reviewDetail:
            return "レビュー"
        }
    }
}
