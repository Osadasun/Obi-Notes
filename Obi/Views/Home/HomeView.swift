//
//  HomeView.swift
//  Obi
//
//  ホーム画面（ジャケットグリッド）
//

import SwiftUI

struct HomeView: View {
    // TODO: ViewModelを追加
    // @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 最新のレビューセクション
                    SectionHeaderView(title: "最新のレビュー", showMore: true)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: gridRows, spacing: 12) {
                            ForEach(0..<9) { index in
                                AlbumCardPlaceholder()
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 今週の人気アルバムセクション
                    SectionHeaderView(title: "今週の人気アルバム", showMore: true)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: gridRows, spacing: 12) {
                            ForEach(0..<9) { index in
                                AlbumCardPlaceholder()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Obi Notes")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // 3行のグリッド
    private var gridRows: [GridItem] {
        Array(repeating: GridItem(.fixed(110), spacing: 12), count: 3)
    }
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    let showMore: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            if showMore {
                Button(action: {
                    // TODO: もっと見る機能
                }) {
                    Text("もっと見る")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Album Card Placeholder
struct AlbumCardPlaceholder: View {
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)

            Text("★★★★★")
                .font(.caption2)
                .foregroundColor(.orange)

            Text("@user")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HomeView()
}
