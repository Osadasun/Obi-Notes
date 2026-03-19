//
//  UserManager.swift
//  Obi
//
//  ユーザー管理（Supabase Auth連携）
//

import Foundation
import Combine

@MainActor
class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published private(set) var currentUserId: UUID?
    @Published private(set) var displayName: String

    private let displayNameKey = "ObiDisplayName"

    private init() {
        // 初期値としてデフォルト表示名を設定
        if let savedName = UserDefaults.standard.string(forKey: displayNameKey) {
            self.displayName = savedName
        } else {
            self.displayName = "User"
        }

        // currentUserIdはnilで初期化（認証後に設定される）
        self.currentUserId = nil
    }

    // MARK: - Authenticated User Management

    /// 認証されたユーザーを設定
    func setAuthenticatedUser(id: UUID, displayName: String) {
        self.currentUserId = id
        self.displayName = displayName
        UserDefaults.standard.set(displayName, forKey: displayNameKey)
        print("✅ 認証ユーザー設定: \(id)")
    }

    /// ユーザー情報をクリア（サインアウト時）
    func clearUser() {
        self.currentUserId = nil
        self.displayName = "User"
        UserDefaults.standard.removeObject(forKey: displayNameKey)
        print("✅ ユーザー情報クリア")
    }

    // MARK: - Profile Management

    func updateDisplayName(_ newName: String) {
        displayName = newName
        UserDefaults.standard.set(newName, forKey: displayNameKey)
    }
}
