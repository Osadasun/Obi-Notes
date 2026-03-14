# 将来実装する機能

Obi Notesの将来的な機能拡張のアイデアと実装メモ

---

## 音楽アプリからの共有機能

### 概要
Spotify/Apple Musicから直接アルバムや楽曲をObiアプリに追加できる機能

### ユースケース
1. SpotifyやApple Musicで音楽を聴いている
2. 「シェア」ボタンをタップ
3. 「Obiに追加」を選択
4. Obiアプリが開いて、自動で情報を取得
5. レビューを書く or マイリストに追加

### 実装方法

#### Phase 1: クリップボード監視（簡単）
- アプリ起動時にクリップボードをチェック
- Apple Music URLを検出したら「追加しますか？」と提案
- URLからAlbum IDを抽出してApple Music APIで情報取得

```swift
// 実装例
if let url = UIPasteboard.general.url,
   let albumId = extractAppleMusicId(from: url) {
    // アルバム情報を取得して追加提案
}

func extractAppleMusicId(from url: URL) -> String? {
    // https://music.apple.com/jp/album/album-name/1234567890
    // → "1234567890" を抽出
    let components = url.pathComponents
    return components.last
}
```

**対応URL：**
- Apple Music: `https://music.apple.com/jp/album/{name}/{id}`
- Apple Music (楽曲): `https://music.apple.com/jp/album/{album-id}?i={track-id}`

---

#### Phase 2: Share Extension（推奨）

iOSの共有拡張機能を使用

**メリット：**
- 他のアプリから直接共有できる
- ネイティブなUX
- URLをコピペ不要

**実装手順：**
1. Xcodeで「Share Extension」ターゲットを追加
2. `Info.plist`でサポートするURLスキームを設定
   - `com.apple.music`
   - `com.spotify.client`
3. URLを受け取って解析
4. アプリのメインターゲットにデータを渡す

```xml
<!-- Info.plist -->
<key>NSExtensionActivationRule</key>
<dict>
    <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
    <integer>1</integer>
    <key>NSExtensionActivationSupportsWebPageWithMaxCount</key>
    <integer>1</integer>
</dict>
```

```swift
// ShareViewController.swift
class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        if let item = extensionContext?.inputItems.first as? NSExtensionItem,
           let itemProvider = item.attachments?.first {

            itemProvider.loadItem(forTypeIdentifier: "public.url") { url, error in
                if let shareURL = url as? URL {
                    // URLを解析してアルバム情報を取得
                    self.handleMusicURL(shareURL)
                }
            }
        }
    }
}
```

---

#### Phase 3: Spotify対応

Spotify URLにも対応する

**課題：**
- Spotify APIは別途認証が必要
- Spotify ID → Apple Music IDへの変換が必要

**解決策：**
1. Spotify APIでアルバム情報を取得
   - アルバム名
   - アーティスト名
   - リリース年
2. Apple Music APIで同じアルバムを検索
3. マッチングしたApple Music IDを使用

```swift
// Spotify URL例
// https://open.spotify.com/album/3jPNMrK3rIcrgKF4M6v9Af

func convertSpotifyToAppleMusic(spotifyId: String) async throws -> String {
    // 1. Spotify APIでアルバム情報取得
    let spotifyAlbum = try await fetchSpotifyAlbum(id: spotifyId)

    // 2. Apple Musicで検索
    let query = "\(spotifyAlbum.name) \(spotifyAlbum.artist)"
    let results = try await AppleMusicService.shared.searchAlbums(query: query)

    // 3. マッチング（名前とアーティストが一致するもの）
    if let match = results.first(where: {
        $0.title.lowercased() == spotifyAlbum.name.lowercased() &&
        $0.artist.lowercased() == spotifyAlbum.artist.lowercased()
    }) {
        return match.id
    }

    throw MusicError.notFound
}
```

---

#### Phase 4: Universal Links（高度）

`obi://` URLスキームでアプリを直接起動

**設定：**
```swift
// Info.plist
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>obi</string>
        </array>
    </dict>
</array>
```

**使用例：**
```
obi://add?url=https://music.apple.com/jp/album/1234567890
```

---

### 技術的な検討事項

#### 1. プライバシー
- クリップボードアクセスは iOS 14+ で通知される
- ユーザーに明示的に許可を求める

#### 2. API制限
- Apple Music API: リクエスト制限に注意
- Spotify API: 認証トークンの管理

#### 3. エラーハンドリング
- URLが無効な場合
- アルバムが見つからない場合
- API制限に達した場合

---

### UI/UX

#### 追加確認ダイアログ
```
┌─────────────────────────────┐
│  アルバムを追加             │
│                             │
│  ┌────────┐                │
│  │ 🎵    │  Album Name     │
│  │        │  Artist Name    │
│  └────────┘                │
│                             │
│  [マイリストに追加]          │
│  [レビューを書く]            │
│  [キャンセル]               │
└─────────────────────────────┘
```

---

### 実装優先度

**Phase 1（MVP後すぐ）:**
- クリップボード監視
- Apple Music URLのみ対応

**Phase 2（成長期）:**
- Share Extension実装
- UX改善

**Phase 3（拡張期）:**
- Spotify対応
- Universal Links

---

### 参考リンク

- [Apple - Share Extension](https://developer.apple.com/documentation/uikit/share_extension)
- [Apple Music API](https://developer.apple.com/documentation/applemusicapi/)
- [Spotify Web API](https://developer.spotify.com/documentation/web-api/)
- [URL Schemes](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)

---

最終更新: 2026-03-14
