//
//  AddToListViewModel.swift
//  Obi
//
//  リスト追加画面のViewModel
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AddToListViewModel: ObservableObject {
    @Published var lists: [MusicList] = []
    @Published var addedListIds: Set<UUID> = []
    @Published var listCounts: [UUID: Int] = [:] // リストの件数を保持
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared

    let targetType: TargetType
    let targetId: String
    let title: String
    let artist: String
    let artworkURL: String?

    init(targetType: TargetType, targetId: String, title: String, artist: String, artworkURL: String?) {
        self.targetType = targetType
        self.targetId = targetId
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
    }

    // MARK: - Computed Properties

    var defaultLists: [MusicList] {
        lists.filter { $0.defaultType != nil }
    }

    var customLists: [MusicList] {
        lists.filter { $0.defaultType == nil }
    }

    // MARK: - Load Lists

    func loadLists() async {
        isLoading = true
        errorMessage = nil

        do {
            // ユーザーの全リストを取得
            lists = try await supabaseService.fetchUserLists()

            // 既に追加されているリストをチェック
            await checkAddedLists()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ リスト取得エラー: \(error)")
        }

        isLoading = false
    }

    // MARK: - Check Added Lists

    private func checkAddedLists() async {
        do {
            // 各リストに対して、このアイテムが含まれているかチェック
            var addedIds: Set<UUID> = []
            var counts: [UUID: Int] = [:]

            for list in lists {
                let items = try await supabaseService.fetchListItems(listId: list.id)
                counts[list.id] = items.count
                if items.contains(where: { $0.targetId == targetId }) {
                    addedIds.insert(list.id)
                }
            }

            addedListIds = addedIds
            listCounts = counts
        } catch {
            print("❌ リストアイテムチェックエラー: \(error)")
        }
    }

    // MARK: - Helper Methods

    func iconForList(_ list: MusicList) -> String {
        guard let defaultType = list.defaultType else {
            return "music.note.list"
        }

        switch defaultType {
        case .reviewed: return "music.note.list"
        case .favorite: return "heart.fill"
        case .listened: return "headphones"
        case .wishlist: return "star.fill"
        }
    }

    func colorForList(_ list: MusicList) -> Color {
        guard let defaultType = list.defaultType else {
            return .purple
        }

        switch defaultType {
        case .reviewed: return .purple
        case .favorite: return .pink
        case .listened: return .blue
        case .wishlist: return .orange
        }
    }

    // MARK: - Toggle List

    func toggleList(_ list: MusicList) async {
        do {
            if addedListIds.contains(list.id) {
                // リストから削除
                try await supabaseService.removeFromList(
                    listId: list.id,
                    targetId: targetId
                )
                addedListIds.remove(list.id)
                print("✅ リストから削除: \(list.name)")
            } else {
                // リストに追加
                try await supabaseService.addToList(
                    listId: list.id,
                    targetType: targetType,
                    targetId: targetId,
                    title: title,
                    artist: artist,
                    artworkURL: artworkURL
                )
                addedListIds.insert(list.id)
                print("✅ リストに追加: \(list.name)")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ リスト操作エラー: \(error)")
        }
    }
}
