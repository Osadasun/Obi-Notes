//
//  AppleMusicConfig.swift
//  Obi
//
//  Apple Music API設定
//

import Foundation

enum AppleMusicConfig {
    // MARK: - Apple Music Configuration
    // TODO: Apple Developer ConsoleでMusicKit識別子を作成し、以下の値を設定してください
    // 詳細は SETUP_INSTRUCTIONS.md の「3. Apple Music APIのセットアップ」を参照

    /// Team ID
    /// Apple Developer Console → Membership で確認
    /// 例: "A1B2C3D4E5"
    static let teamId = "YOUR_TEAM_ID"

    /// MusicKit Key ID
    /// Apple Developer Console → Keys で作成したMusicKitキーのID
    /// 例: "F6G7H8I9J0"
    static let keyId = "YOUR_KEY_ID"

    /// MusicKit Private Key (.p8ファイルの内容)
    /// Apple Developer Consoleからダウンロードした.p8ファイルの内容
    /// 注意: このファイルは一度しかダウンロードできません
    static let privateKey = """
    -----BEGIN PRIVATE KEY-----
    YOUR_PRIVATE_KEY_CONTENT_HERE
    -----END PRIVATE KEY-----
    """

    // MARK: - Validation
    static var isConfigured: Bool {
        return teamId != "YOUR_TEAM_ID" &&
               keyId != "YOUR_KEY_ID" &&
               !privateKey.contains("YOUR_PRIVATE_KEY_CONTENT_HERE")
    }
}

// MARK: - セキュリティノート
/*
 重要: このファイルは機密情報を含むため、.gitignore に追加すべきです。

 本番環境での推奨設定方法:

 1. 環境変数を使用（推奨）
    - Xcodeの Build Settings で環境変数を設定
    - またはCI/CDで環境変数を注入

 2. .xcconfigファイルを使用
    - Config.xcconfig ファイルに設定を記述
    - .gitignore に追加して秘密を保持

 3. Keychainを使用（高度）
    - iOSキーチェーンに秘密鍵を保存
    - アプリ起動時に取得

 開発時の注意:
 - このファイルをGitHubにプッシュしないこと
 - チームメンバーには Config.example.swift を共有
 - 実際の値は個別に設定してもらう
 */
