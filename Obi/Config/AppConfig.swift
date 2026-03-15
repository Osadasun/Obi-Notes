//
//  AppConfig.swift
//  Obi
//
//  アプリケーション設定
//

import Foundation

enum AppConfig {
    // MARK: - Development Mode

    /// 開発モード（Apple Music APIの代わりにモックデータを使用）
    /// Apple Developer Programに登録していない場合はtrueに設定
    static let useMockMusicService = false

    /// デバッグログを表示するか
    static let showDebugLogs = true
}
