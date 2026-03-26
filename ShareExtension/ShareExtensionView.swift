//
//  ShareExtensionView.swift
//  ShareExtension
//
//  Spotify/Apple Musicから共有された音楽を「聴いた」リストに追加するUI
//

import SwiftUI
import MusicKit

struct ShareExtensionView: View {
    let url: URL
    let onComplete: (Bool) -> Void

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var albumInfo: SharedAlbumData?
    @State private var parsedURL: ParsedMusicURL?
    @State private var isMusicAuthorized = false
    @State private var debugMessage: String = ""

    var body: some View {
        VStack(spacing: 24) {
            // ヘッダー
            VStack(spacing: 8) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 48))
                    .foregroundColor(.purple)

                Text("Obiに追加")
                    .font(.title2)
                    .fontWeight(.bold)
                    
                // デバッグ表示
                if !debugMessage.isEmpty {
                    Text(debugMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 32)

            // コンテンツ
            if isLoading {
                ProgressView("音楽情報を取得中...")
                    .padding()
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)

                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else if let albumInfo = albumInfo {
                // アルバム情報表示
                VStack(spacing: 16) {
                    // アートワーク
                    if let artworkURL = albumInfo.artworkURL, let url = URL(string: artworkURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 150, height: 150)
                        .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 150, height: 150)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                            )
                    }

                    VStack(spacing: 4) {
                        Text(albumInfo.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        Text(albumInfo.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    Text("「聴いた」リストに追加されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // アクションボタン
                VStack(spacing: 12) {
                    Button(action: {
                        addToListenedList()
                    }) {
                        Text("追加")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        onComplete(false)
                    }) {
                        Text("キャンセル")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .task {
            await checkMusicAuthorization()
            if isMusicAuthorized {
                parseURL()
            } else {
                errorMessage = "Apple Musicへのアクセスが許可されていません。\n設定からアクセスを許可してください。"
                isLoading = false
            }
        }
    }

    private func checkMusicAuthorization() async {
        let status = await MusicAuthorization.request()
        isMusicAuthorized = (status == .authorized)
        print("🎵 [ShareExtension] MusicKit Authorization: \(status)")
    }

    private func parseURL() {
        print("🔍 [ShareExtension] Parsing URL: \(url.absoluteString)")
        
        // URLを解析
        guard let parsed = MusicURLParser.parse(url: url) else {
            print("❌ [ShareExtension] URL parse failed")
            errorMessage = "このURLはサポートされていません"
            isLoading = false
            return
        }

        print("✅ [ShareExtension] URL parsed: \(parsed)")
        parsedURL = parsed

        // SpotifyはIDからアルバム情報を取得できないため、エラー表示
        if parsed.service == .spotify {
            errorMessage = "Spotifyからの共有は現在サポートされていません。\nApple Musicをご利用ください。"
            isLoading = false
            return
        }

        // Apple MusicのIDから情報を取得
        if parsed.service == .appleMusic, let albumId = parsed.albumId {
            print("📀 [ShareExtension] Fetching album: \(albumId)")
            Task {
                await fetchAlbumInfo(appleMusicId: albumId)
            }
        } else {
            print("❌ [ShareExtension] No album ID found")
            errorMessage = "アルバム情報を取得できませんでした"
            isLoading = false
        }
    }

    private func fetchAlbumInfo(appleMusicId: String) async {
        do {
            print("📡 [ShareExtension] Calling MusicKit API...")
            
            // MusicKit APIからアルバム情報を取得
            let musicItemID = MusicItemID(appleMusicId)
            let request = MusicCatalogResourceRequest<MusicKit.Album>(matching: \.id, equalTo: musicItemID)
            let response = try await request.response()

            guard let musicKitAlbum = response.items.first else {
                print("❌ [ShareExtension] Album not found in response")
                errorMessage = "アルバムが見つかりませんでした"
                isLoading = false
                return
            }

            // SharedAlbumDataに変換
            let album = SharedAlbumData(
                albumId: appleMusicId,
                title: musicKitAlbum.title,
                artist: musicKitAlbum.artistName,
                artworkURL: musicKitAlbum.artwork?.url(width: 300, height: 300)?.absoluteString
            )

            self.albumInfo = album
            self.isLoading = false

            print("✅ [ShareExtension] アルバム情報取得成功: \(album.title)")
        } catch {
            print("❌ [ShareExtension] アルバム情報取得エラー: \(error)")
            errorMessage = "アルバム情報の取得に失敗しました。\n\(error.localizedDescription)"
            isLoading = false
        }
    }

    private func addToListenedList() {
        guard let albumInfo = albumInfo else {
            print("❌ [ShareExtension] albumInfo is nil")
            debugMessage = "Error: albumInfo is nil"
            return
        }

        print("📋 [ShareExtension] Adding to pending: \(albumInfo.title)")
        print("📋 [ShareExtension] Album ID: \(albumInfo.albumId)")
        print("📋 [ShareExtension] Artist: \(albumInfo.artist)")
        
        // App Group確認
        let appGroupIdentifier = "group.com.osadskosuke.Obi"
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ [ShareExtension] App Group UserDefaults is nil!")
            debugMessage = "Error: App Group access failed"
            return
        }
        
        print("✅ [ShareExtension] App Group UserDefaults created successfully")
        
        // App Group経由でメインアプリにデータを渡す
        AppGroupManager.shared.addPendingAlbum(albumInfo)
        
        // 保存確認
        let savedAlbums = AppGroupManager.shared.getPendingAlbums()
        print("✅ [ShareExtension] 保留中のアルバム数: \(savedAlbums.count)")
        debugMessage = "Saved! Count: \(savedAlbums.count)"
        
        for (index, album) in savedAlbums.enumerated() {
            print("   [\(index)] \(album.title) - \(album.artist)")
        }

        // 2秒待ってから閉じる（デバッグメッセージを見るため）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("✅ [ShareExtension] Calling onComplete(true)")
            onComplete(true)
        }
    }
}

#Preview {
    ShareExtensionView(
        url: URL(string: "https://music.apple.com/jp/album/1234567890")!,
        onComplete: { _ in }
    )
}
