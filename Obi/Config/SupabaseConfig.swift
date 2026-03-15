//
//  SupabaseConfig.swift
//  Obi
//
//  Supabase接続設定
//

import Foundation

enum SupabaseConfig {
    static let url = "https://ctvhpcwjeriozjxqwbao.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0dmhwY3dqZXJpb3pqeHF3YmFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0OTM0MTAsImV4cCI6MjA4OTA2OTQxMH0.sP1fhz2Zk36ceB6uGYNZRjdEtCTL9ubWPTSkl5XKcX8"

    static var isConfigured: Bool {
        return !url.isEmpty && !anonKey.isEmpty
    }
}
