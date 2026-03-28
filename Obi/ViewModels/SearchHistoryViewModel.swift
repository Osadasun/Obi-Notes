//
//  SearchHistoryViewModel.swift
//  Obi
//
//  検索履歴のViewModel
//

import Foundation
import Combine

@MainActor
class SearchHistoryViewModel: ObservableObject {
    @Published var recentSearches: [String] = []

    private let maxHistoryCount = 10
    private let userDefaultsKey = "recentSearches"

    init() {
        loadSearchHistory()
    }

    func loadSearchHistory() {
        if let saved = UserDefaults.standard.stringArray(forKey: userDefaultsKey) {
            recentSearches = saved
        }
    }

    func addSearch(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // 既存の同じ検索を削除
        recentSearches.removeAll { $0 == query }

        // 先頭に追加
        recentSearches.insert(query, at: 0)

        // 最大件数を超えたら削除
        if recentSearches.count > maxHistoryCount {
            recentSearches = Array(recentSearches.prefix(maxHistoryCount))
        }

        // 保存
        UserDefaults.standard.set(recentSearches, forKey: userDefaultsKey)
    }

    func removeSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        UserDefaults.standard.set(recentSearches, forKey: userDefaultsKey)
    }

    func clearAll() {
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
