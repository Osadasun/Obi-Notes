//
//  SearchView.swift
//  Obi
//
//  検索画面
//

import SwiftUI

struct SearchView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                if searchText.isEmpty {
                    // 検索前の状態
                    ContentUnavailableView(
                        "音楽を検索",
                        systemImage: "magnifyingglass",
                        description: Text("アルバムやアーティストを検索してレビューを書こう")
                    )
                } else {
                    // 検索結果
                    List {
                        Section("アルバム") {
                            ForEach(0..<5) { index in
                                Text("アルバム \(index)")
                            }
                        }

                        Section("楽曲") {
                            ForEach(0..<5) { index in
                                Text("楽曲 \(index)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("検索")
            .searchable(text: $searchText, prompt: "アルバム、アーティスト、楽曲")
        }
    }
}

#Preview {
    SearchView()
}
