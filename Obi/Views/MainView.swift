//
//  MainView.swift
//  Obi
//
//  メインビュー（ヘッダー切り替え + フローティングボタン）
//

import SwiftUI

struct MainView: View {
    @State private var selectedFeed: Feed = .home
    @State private var showSearch = false
    @State private var showCreateReview = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // メインコンテンツ
                VStack(spacing: 0) {
                    // カスタムヘッダー
                    HeaderSwitcher(selectedFeed: $selectedFeed)

                    Divider()

                    // コンテンツ
                    Group {
                        switch selectedFeed {
                        case .home:
                            HomeView()
                        case .obi:
                            ObiView()
                        }
                    }
                }

                // フローティングアクションボタン
                VStack(spacing: 16) {
                    // 検索ボタン
                    FloatingButton(
                        icon: "magnifyingglass",
                        backgroundColor: .white,
                        foregroundColor: .purple
                    ) {
                        showSearch = true
                    }

                    // レビュー作成ボタン
                    FloatingButton(
                        icon: "plus",
                        backgroundColor: .purple,
                        foregroundColor: .white,
                        size: 56
                    ) {
                        showCreateReview = true
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
            }
            .sheet(isPresented: $showCreateReview) {
                CreateReviewView()
            }
        }
    }
}

// MARK: - Feed Type
enum Feed: String, CaseIterable {
    case home = "Home"
    case obi = "Obi"
}

// MARK: - Header Switcher
struct HeaderSwitcher: View {
    @Binding var selectedFeed: Feed
    @State private var showDropdown = false

    var body: some View {
        HStack(spacing: 16) {
            // 左側: 切り替えメニュー
            Menu {
                ForEach(Feed.allCases, id: \.self) { feed in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFeed = feed
                        }
                    }) {
                        HStack {
                            Text(feed.rawValue)
                            if selectedFeed == feed {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedFeed.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 右側: プロフィールボタン
            NavigationLink(destination: ProfileView()) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
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

// MARK: - Obi View (Following Feed)
struct ObiView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("フォロー中のレビュー")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)

                // TODO: フォロー中のユーザーのレビューを表示
                ContentUnavailableView(
                    "フォロー中のユーザーがいません",
                    systemImage: "person.2.slash",
                    description: Text("気になるユーザーをフォローしてレビューをチェックしよう")
                )
            }
        }
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
