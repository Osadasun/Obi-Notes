//
//  AuthenticationViewModel.swift
//  Obi
//
//  認証管理ViewModel
//

import Foundation
import Combine
import AuthenticationServices
import Auth

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var showError = false

    private let supabaseService = SupabaseService.shared

    init() {
        checkAuthenticationState()
    }

    // MARK: - Authentication State

    func checkAuthenticationState() {
        Task {
            isLoading = true

            // Supabaseのセッションをチェック
            if let user = await supabaseService.currentUser {
                print("✅ 既存セッション検出: \(user.id)")

                // profilesテーブルにユーザーが存在するか確認
                do {
                    _ = try await supabaseService.fetchUser(id: user.id)
                    print("✅ ユーザープロフィール確認完了")
                    isAuthenticated = true

                    // UserManagerを更新
                    UserManager.shared.setAuthenticatedUser(id: user.id, displayName: user.email ?? "User")
                } catch {
                    print("⚠️ プロフィールが存在しないため作成します")
                    await createUserProfile(userId: user.id, email: user.email)
                }
            } else {
                print("ℹ️ セッションなし - サインインが必要")
                isAuthenticated = false
            }

            isLoading = false
        }
    }

    // MARK: - Apple Sign In

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showErrorMessage("Apple認証情報の取得に失敗しました")
                return
            }

            guard let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                showErrorMessage("トークンの取得に失敗しました")
                return
            }

            // Supabaseで認証
            do {
                let nonce = UUID().uuidString // 本番環境では適切なnonce生成を使用
                try await supabaseService.signInWithApple(idToken: tokenString, nonce: nonce)

                // 認証成功後、ユーザー情報を取得
                guard let user = await supabaseService.currentUser else {
                    showErrorMessage("ユーザー情報の取得に失敗しました")
                    return
                }

                print("✅ Apple Sign In成功: \(user.id)")

                // プロフィールを作成または取得
                let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                let finalDisplayName = displayName.isEmpty ? (user.email ?? "User") : displayName

                do {
                    _ = try await supabaseService.fetchUser(id: user.id)
                    print("✅ 既存ユーザー")
                } catch {
                    print("⚠️ 新規ユーザー - プロフィール作成")
                    await createUserProfile(userId: user.id, email: user.email, displayName: finalDisplayName)
                }

                // UserManagerを更新
                UserManager.shared.setAuthenticatedUser(id: user.id, displayName: finalDisplayName)

                isAuthenticated = true

            } catch {
                print("❌ Apple Sign Inエラー: \(error)")
                showErrorMessage("サインインに失敗しました: \(error.localizedDescription)")
            }

        case .failure(let error):
            print("❌ Apple認証エラー: \(error)")
            if (error as NSError).code != 1001 { // キャンセル以外のエラー
                showErrorMessage("認証に失敗しました")
            }
        }
    }

    // MARK: - Development Sign In (デバイスIDベース)

    func signInWithDevMode() async {
        isLoading = true

        // デバイスベースのUUID生成
        let deviceId: UUID
        if let savedIdString = UserDefaults.standard.string(forKey: "DevModeUserId"),
           let savedId = UUID(uuidString: savedIdString) {
            deviceId = savedId
        } else {
            deviceId = UUID()
            UserDefaults.standard.set(deviceId.uuidString, forKey: "DevModeUserId")
        }

        let displayName = "Dev User (\(deviceId.uuidString.prefix(8)))"

        // プロフィールを作成または確認
        do {
            _ = try await supabaseService.fetchUser(id: deviceId)
            print("✅ 開発用ユーザーは既に存在します: \(deviceId)")
        } catch {
            print("⚠️ 開発用ユーザー新規作成: \(deviceId)")
            await createUserProfile(userId: deviceId, email: nil, displayName: displayName)
        }

        // UserManagerを更新
        UserManager.shared.setAuthenticatedUser(id: deviceId, displayName: displayName)
        isAuthenticated = true
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await supabaseService.signOut()
            UserManager.shared.clearUser()
            isAuthenticated = false
            print("✅ サインアウト成功")
        } catch {
            print("❌ サインアウトエラー: \(error)")
            showErrorMessage("サインアウトに失敗しました")
        }
    }

    // MARK: - Private Helpers

    private func createUserProfile(userId: UUID, email: String?, displayName: String? = nil) async {
        let newUser = User(
            id: userId,
            displayName: displayName ?? email ?? "User",
            photoURL: nil,
            bio: nil,
            createdAt: Date()
        )

        do {
            _ = try await supabaseService.createUser(newUser)
            print("✅ ユーザープロフィール作成成功")
            isAuthenticated = true
        } catch {
            print("❌ ユーザープロフィール作成エラー: \(error)")
            showErrorMessage("プロフィールの作成に失敗しました")
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
