//
//  AppleMusicConfig.example.swift
//  Obi
//
//  Apple Music API設定（テンプレート）
//
//  使い方:
//  1. このファイルを AppleMusicConfig.swift にコピー
//  2. YOUR_TEAM_ID、YOUR_KEY_ID、YOUR_PRIVATE_KEY_CONTENT_HERE を実際の値に置き換え
//  3. SETUP_INSTRUCTIONS.md の手順に従ってMusicKit識別子を作成
//

import Foundation

enum AppleMusicConfig {
    // MARK: - Apple Music Configuration

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
