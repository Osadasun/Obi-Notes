//
//  MainTabView.swift
//  Obi
//
//  メインタブビュー
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authViewModel.isLoading {
                // ローディング画面
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("読み込み中...")
                        .foregroundColor(.secondary)
                }
            } else if authViewModel.isAuthenticated {
                // 認証済み - メインタブを表示
                TabView(selection: $selectedTab) {
                    // ホームタブ
                    HomeView(bottomSpacerHeight: 0)
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
                    ProfileView(authViewModel: authViewModel)
                        .tabItem {
                            Label("マイページ", systemImage: "person.fill")
                        }
                        .tag(3)
                }
                .tint(.purple) // タブのアクセントカラー
            } else {
                // 未認証 - サインイン画面を表示
                SignInView(authViewModel: authViewModel)
            }
        }
    }
}

#Preview {
    MainTabView()
}
