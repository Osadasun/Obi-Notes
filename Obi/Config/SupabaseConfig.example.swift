//
//  SupabaseConfig.example.swift
//  Obi
//
//  Supabase接続設定（テンプレート）
//
//  使い方:
//  1. このファイルを SupabaseConfig.swift にコピー
//  2. YOUR_SUPABASE_URL と YOUR_SUPABASE_ANON_KEY を実際の値に置き換え
//  3. SUPABASE_SETUP.md の手順に従ってSupabaseプロジェクトを作成
//

import Foundation

enum SupabaseConfig {
    // MARK: - Supabase Configuration

    /// Supabase Project URL
    /// Supabaseダッシュボード → Settings → API で確認
    /// 例: "https://xxxxx.supabase.co"
    static let url = "YOUR_SUPABASE_URL"

    /// Supabase Anon Key (公開用)
    /// Supabaseダッシュボード → Settings → API で確認
    /// 例: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    static let anonKey = "YOUR_SUPABASE_ANON_KEY"

    // MARK: - Validation
    static var isConfigured: Bool {
        return url != "YOUR_SUPABASE_URL" && anonKey != "YOUR_SUPABASE_ANON_KEY"
    }
}
