//
//  MainTabView.swift
//  Obi
//
//  メインタブビュー
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // ホームタブ
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)

            // 検索タブ
            SearchView()
                .tabItem {
                    Label("検索", systemImage: "magnifyingglass")
                }
                .tag(1)

            // レビュー作成タブ（中央の+ボタン）
            Text("レビュー作成")
                .tabItem {
                    Label("レビュー", systemImage: "plus.circle.fill")
                }
                .tag(2)

            // プロフィールタブ
            ProfileView()
                .tabItem {
                    Label("マイページ", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.purple) // タブのアクセントカラー
    }
}

#Preview {
    MainTabView()
}
