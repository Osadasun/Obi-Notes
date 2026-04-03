//
//  ObiPageContent.swift
//  Obi
//
//  Obiページのコンテンツタイプ定義
//

import Foundation

enum ObiPageContent: Identifiable, Equatable {
    case cardList
    case myReviews
    case defaultList(MyListCategory)
    case customList(MusicList)
    case userAlbum(UserAlbum)
    case albumDetail(Album)
    case trackDetail(Track)
    case reviewDetail(Review)

    var id: String {
        switch self {
        case .cardList:
            return "cardList"
        case .myReviews:
            return "myReviews"
        case .defaultList(let category):
            return "defaultList_\(category.rawValue)"
        case .customList(let list):
            return "customList_\(list.id.uuidString)"
        case .userAlbum(let album):
            return "userAlbum_\(album.id)"
        case .albumDetail(let album):
            return "albumDetail_\(album.id)"
        case .trackDetail(let track):
            return "trackDetail_\(track.id)"
        case .reviewDetail(let review):
            return "reviewDetail_\(review.id)"
        }
    }

    var title: String {
        switch self {
        case .cardList:
            return "Obi"
        case .myReviews:
            return "マイレビュー"
        case .defaultList(let category):
            return category.rawValue
        case .customList(let list):
            return list.name
        case .userAlbum(let album):
            return album.name
        case .albumDetail(let album):
            return album.title
        case .trackDetail(let track):
            return track.title
        case .reviewDetail:
            return ""
        }
    }
}
