//
//  AppGroupManager.swift
//  Obi
//
//  App Groupを使ったデータ共有マネージャー
//

import Foundation

class AppGroupManager {
    static let shared = AppGroupManager()

    private let appGroupIdentifier = "group.com.osadskosuke.Obi"
    private let pendingAlbumsKey = "pendingAlbums"

    private init() {}

    /// UserDefaults（App Group）を取得
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Pending Albums Management

    /// 保留中のアルバムリストを取得
    func getPendingAlbums() -> [SharedAlbumData] {
        guard let sharedDefaults = sharedDefaults,
              let data = sharedDefaults.data(forKey: pendingAlbumsKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let pendingData = try decoder.decode(PendingAlbumsData.self, from: data)
            return pendingData.albums
        } catch {
            print("❌ 保留中アルバムの読み込みエラー: \(error)")
            return []
        }
    }

    /// 保留中のアルバムリストに追加
    func addPendingAlbum(_ album: SharedAlbumData) {
        var albums = getPendingAlbums()
        albums.append(album)
        savePendingAlbums(albums)
    }

    /// 保留中のアルバムリストを保存
    private func savePendingAlbums(_ albums: [SharedAlbumData]) {
        guard let sharedDefaults = sharedDefaults else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let pendingData = PendingAlbumsData(albums: albums)
            let data = try encoder.encode(pendingData)
            sharedDefaults.set(data, forKey: pendingAlbumsKey)
            sharedDefaults.synchronize()
            print("✅ 保留中アルバムを保存: \(albums.count)件")
        } catch {
            print("❌ 保留中アルバムの保存エラー: \(error)")
        }
    }

    /// 保留中のアルバムリストをクリア
    func clearPendingAlbums() {
        guard let sharedDefaults = sharedDefaults else { return }
        sharedDefaults.removeObject(forKey: pendingAlbumsKey)
        sharedDefaults.synchronize()
        print("✅ 保留中アルバムをクリア")
    }

    /// 特定のアルバムを保留リストから削除
    func removePendingAlbum(albumId: String) {
        var albums = getPendingAlbums()
        albums.removeAll { $0.albumId == albumId }
        savePendingAlbums(albums)
    }
}
