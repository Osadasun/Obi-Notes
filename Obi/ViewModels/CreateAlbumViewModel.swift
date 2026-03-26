//
//  CreateAlbumViewModel.swift
//  Obi
//
//  ユーザーアルバム作成画面のViewModel
//

import Foundation
import Combine
import SwiftUI

@MainActor
class CreateAlbumViewModel: ObservableObject {
    @Published var albumName = ""
    @Published var selectedColor: Color = .purple
    @Published var isCreating = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared

    // よく使われる色のプリセット
    let colorPresets: [Color] = [
        .purple, .blue, .green, .orange, .red, .pink,
        .yellow, .indigo, .teal, .mint, .cyan, .brown
    ]

    var canCreate: Bool {
        !albumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func createAlbum() async -> Bool {
        guard canCreate else {
            errorMessage = "アルバム名を入力してください"
            return false
        }

        guard let userId = UserManager.shared.currentUserId else {
            errorMessage = "ログインしてください"
            return false
        }

        isCreating = true
        errorMessage = nil

        do {
            let colorHex = selectedColor.toHex()
            let artistName = UserManager.shared.displayName
            _ = try await supabaseService.createUserAlbum(
                userId: userId.uuidString,
                name: albumName.trimmingCharacters(in: .whitespacesAndNewlines),
                artistName: artistName,
                colorHex: colorHex
            )

            print("✅ [CreateAlbum] Album created: \(albumName) by \(artistName)")
            isCreating = false
            return true
        } catch {
            print("❌ [CreateAlbum] Failed to create album: \(error)")
            errorMessage = "アルバムの作成に失敗しました"
            isCreating = false
            return false
        }
    }
}

// Color to Hex extension
extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
