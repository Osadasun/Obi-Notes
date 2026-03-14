//
//  SupabaseConfig.swift
//  Obi
//
//  Supabase接続設定
//

import Foundation

enum SupabaseConfig {
    // MARK: - Supabase Configuration
    // TODO: SUPABASE_SETUP.mdの手順に従ってプロジェクトを作成し、以下の値を設定してください

    /// Supabase Project URL
    /// 例: "https://xxxxx.supabase.co"
    static let url = "YOUR_SUPABASE_URL"

    /// Supabase Anon Key (公開用)
    /// 例: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    static let anonKey = "YOUR_SUPABASE_ANON_KEY"

    // MARK: - Validation
    static var isConfigured: Bool {
        return url != "YOUR_SUPABASE_URL" && anonKey != "YOUR_SUPABASE_ANON_KEY"
    }
}

// MARK: - セキュリティノート
/*
 重要: この設定ファイルは .gitignore に追加すべきですが、
 今回はデモのため含めています。

 本番環境では:
 1. このファイルを .gitignore に追加
 2. SupabaseConfig.example.swift をリポジトリに含める
 3. チームメンバーは example をコピーして実際の値を設定

 または:
 1. Xcodeの Build Settings で環境変数として設定
 2. Info.plist に設定（推奨しない）
 3. .xcconfig ファイルを使用（推奨）
 */
