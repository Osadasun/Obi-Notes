//
//  DeepLinkManager.swift
//  Obi
//
//  Deep Link管理クラス
//

import Foundation
import Combine

enum MusicTargetType: String {
    case album
    case track
}

struct PendingMusic: Equatable {
    let id: String
    let type: MusicTargetType
}

class DeepLinkManager: ObservableObject {
    @Published var pendingMusic: PendingMusic?

    func handleURL(_ url: URL) {
        print("🔗 [DeepLinkManager] Handling URL: \(url.absoluteString)")

        guard url.scheme == "obi" else {
            print("❌ [DeepLinkManager] Invalid scheme: \(url.scheme ?? "nil")")
            return
        }

        if url.host == "add-music" {
            // クエリパラメータからIDとtypeを取得
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let id = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let typeString = components.queryItems?.first(where: { $0.name == "type" })?.value,
               let type = MusicTargetType(rawValue: typeString) {
                print("✅ [DeepLinkManager] Music ID: \(id), Type: \(type)")
                self.pendingMusic = PendingMusic(id: id, type: type)
            }
        }
    }

    func clearPendingMusic() {
        pendingMusic = nil
    }
}
