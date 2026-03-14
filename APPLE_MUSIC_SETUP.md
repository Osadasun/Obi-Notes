# Apple Music API セットアップガイド

Apple Music APIをObi Notesで使用するための設定手順

---

## 1. Info.plist にプライバシー設定を追加

### Xcode で設定する方法（推奨）

1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲーターで `Obi` → `Obi` ターゲットを選択
3. **Info** タブを開く
4. **Custom iOS Target Properties** セクションで右クリック → **Add Row**
5. 以下を追加：

| Key | Type | Value |
|-----|------|-------|
| `Privacy - Media Library Usage Description` | String | `音楽情報を取得してレビューを作成するために使用します` |

または、

| Key | Type | Value |
|-----|------|-------|
| `NSAppleMusicUsageDescription` | String | `音楽情報を取得してレビューを作成するために使用します` |

---

## 2. Apple Developer での設定（本番用）

### Step 1: App ID の作成

1. https://developer.apple.com にログイン
2. **Certificates, Identifiers & Profiles** を開く
3. **Identifiers** → **+** ボタン
4. **App IDs** を選択 → Continue
5. 以下を入力：
   - Description: `Obi Notes`
   - Bundle ID: `com.yourname.Obi` (明示的)
6. **Capabilities** で **MusicKit** にチェック
7. Continue → Register

### Step 2: MusicKit の有効化

1. 作成した App ID を選択
2. **Edit** をクリック
3. **MusicKit** にチェックが入っていることを確認
4. Save

---

## 3. Xcode プロジェクトでの設定

### Signing & Capabilities

1. Xcodeでプロジェクトを開く
2. プロジェクト設定 → **Obi** ターゲット
3. **Signing & Capabilities** タブ
4. **+ Capability** をクリック
5. 検索バーで「MusicKit」を検索
6. **MusicKit** を追加

---

## 4. 動作確認

### 基本的な使用方法

```swift
import MusicKit

// 権限をリクエスト
let authorized = await AppleMusicService.shared.requestAuthorization()

if authorized {
    // 音楽検索
    let albums = try await AppleMusicService.shared.searchAlbums(query: "The Beatles")
    print("Found \(albums.count) albums")

    // アルバム詳細取得
    if let album = albums.first {
        let details = try await AppleMusicService.shared.fetchAlbum(id: album.id)
        print("Album: \(details.title) by \(details.artist)")
    }
} else {
    print("Apple Music authorization denied")
}
```

---

## 5. トラブルシューティング

### エラー: "MusicKit authorization failed"

**原因:**
- Info.plist に `NSAppleMusicUsageDescription` がない
- ユーザーが権限を拒否した

**解決策:**
1. Info.plist を確認
2. シミュレータの場合:
   - 設定 → プライバシーとセキュリティ → メディアとApple Music
   - アプリの権限を確認

### エラー: "No such module 'MusicKit'"

**原因:**
- iOS のターゲットバージョンが低い

**解決策:**
- プロジェクト設定で iOS Deployment Target を 15.0 以上に設定

### 検索結果が空

**原因:**
- Apple Music カタログが利用できない地域
- ネットワーク接続の問題

**解決策:**
1. インターネット接続を確認
2. シミュレータの場合、Apple ID でサインインしているか確認

---

## 6. 開発時の注意点

### Apple Music サブスクリプション

- MusicKitは**Apple Music サブスクリプション不要**
- カタログ検索は誰でも可能
- 再生機能は Apple Music サブスクリプションが必要（Obiでは使用しない）

### レート制限

- Apple Music API にはレート制限あり
- 過度なリクエストは避ける
- キャッシュを活用する

### プライバシー

- ユーザーの音楽ライブラリにはアクセスしない（Obiでは不要）
- カタログ検索のみ使用

---

## 7. 実装済み機能

### AppleMusicService.swift

✅ **認証**
- `requestAuthorization()` - 権限リクエスト
- `isAuthorized` - 権限状態確認

✅ **検索**
- `searchMusic(query)` - アルバムと楽曲を同時検索
- `searchAlbums(query, limit)` - アルバムのみ検索
- `searchTracks(query, limit)` - 楽曲のみ検索

✅ **詳細取得**
- `fetchAlbum(id)` - アルバム詳細
- `fetchTrack(id)` - 楽曲詳細

### データ変換

MusicKit の型 → Obi のカスタム型に変換済み:
- `MusicKit.Album` → `Album`
- `MusicKit.Song` → `Track`

---

## 次のステップ

1. ✅ AppleMusicService 実装完了
2. ⏳ Info.plist にプライバシー設定を追加
3. ⏳ SearchView で AppleMusicService を使用
4. ⏳ 検索結果の表示UI作成
5. ⏳ アルバム詳細画面の実装

---

最終更新: 2026-03-14
