//
//  DeepLinkManager.swift
//  Obi
//
//  Deep Link管理クラス
//

import Foundation
import Combine

class DeepLinkManager: ObservableObject {
    @Published var pendingAlbumId: String?

    func handleURL(_ url: URL) {
        print("🔗 [DeepLinkManager] Handling URL: \(url.absoluteString)")

        guard url.scheme == "obi" else {
            print("❌ [DeepLinkManager] Invalid scheme: \(url.scheme ?? "nil")")
            return
        }

        if url.host == "add-album" {
            // クエリパラメータからアルバムIDを取得
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let albumId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                print("✅ [DeepLinkManager] Album ID: \(albumId)")
                self.pendingAlbumId = albumId
            }
        }
    }

    func clearPendingAlbumId() {
        pendingAlbumId = nil
    }
}
