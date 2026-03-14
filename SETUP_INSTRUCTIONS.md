# セットアップ手順書

Obi Notesアプリの開発環境セットアップ手順

---

## 1. Supabase Swift SDKの追加

### Step 1: Xcodeでプロジェクトを開く
1. Xcodeで `Obi.xcodeproj` を開く
2. プロジェクトナビゲーターで一番上の「Obi」プロジェクトをクリック

### Step 2: Swift Package Managerで依存関係を追加
1. Xcodeメニューバーから **File → Add Package Dependencies...** を選択
2. 検索バーに以下のURLを入力：
   ```
   https://github.com/supabase/supabase-swift
   ```
3. 「Add Package」をクリック
4. パッケージが読み込まれたら、以下を選択：
   - ✅ **Supabase**
   - ✅ **Auth**
   - ✅ **PostgREST**
   - ✅ **Storage**
   - ✅ **Realtime**（オプション）
5. 「Add Package」をクリックして完了

### Step 3: 正しくインポートされたか確認
以下のコマンドで確認できます：
```bash
# プロジェクトディレクトリで実行
xcodebuild -list
```

または、Xcodeの「Package Dependencies」セクションに「supabase-swift」が表示されていればOK

---

## 2. Supabaseプロジェクトのセットアップ

詳細は [SUPABASE_SETUP.md](SUPABASE_SETUP.md) を参照してください。

### クイックスタート

1. **Supabaseアカウント作成**
   - https://supabase.com にアクセス
   - GitHubでサインアップ

2. **プロジェクト作成**
   - プロジェクト名: `obi-notes`
   - Region: `Northeast Asia (Tokyo)`
   - データベースパスワードを設定（必ず保存！）

3. **データベーススキーマ作成**
   - Supabaseダッシュボードで「SQL Editor」を開く
   - [SUPABASE_SETUP.md](SUPABASE_SETUP.md) のSQLを実行

4. **API情報をアプリに設定**
   - Supabaseダッシュボードで「Settings → API」を開く
   - `Project URL` と `anon public` キーをコピー
   - `Obi/Config/SupabaseConfig.swift` を編集：

```swift
enum SupabaseConfig {
    static let url = "YOUR_PROJECT_URL" // ここに貼り付け
    static let anonKey = "YOUR_ANON_KEY" // ここに貼り付け
}
```

---

## 3. Apple Music APIのセットアップ

### Step 1: Apple Developer Programに登録
1. https://developer.apple.com にアクセス
2. Apple Developer Programに登録（年間¥12,980）
   - 個人開発者として登録
   - 法人の場合は法人として登録

### Step 2: MusicKit識別子の作成
1. Apple Developer Consoleにログイン
2. **Certificates, Identifiers & Profiles** を開く
3. **Identifiers** → **+** ボタンをクリック
4. **Services IDs** を選択
5. 以下を入力：
   - Description: `Obi Notes MusicKit`
   - Identifier: `com.yourname.obi.musickit`
6. 「Continue」→ 「Register」

### Step 3: MusicKit Private Keyの作成
1. **Keys** セクションに移動
2. **+** ボタンをクリック
3. **MusicKit** にチェック
4. Key Name: `Obi Notes MusicKit Key`
5. 「Continue」→ 「Register」
6. **Downloadボタンをクリックして.p8ファイルを保存**（これは一度しかダウンロードできません！）
7. **Key ID** をメモ（後で使います）

### Step 4: Team IDを確認
1. Apple Developer Consoleで「Membership」を開く
2. **Team ID** をメモ

### Step 5: Xcodeプロジェクトに設定
1. Xcodeでプロジェクトを開く
2. プロジェクト設定 → **Signing & Capabilities** タブ
3. **+ Capability** をクリック
4. 「App Groups」を検索して追加（オプション）
5. **Info.plist** に以下を追加：

**Info.plist（テキストエディタで開く）:**
```xml
<key>NSAppleMusicUsageDescription</key>
<string>音楽情報を取得してレビューを作成するために使用します</string>
```

**または、Xcodeのプロパティリストエディタで：**
- Key: `Privacy - Media Library Usage Description`
- Value: `音楽情報を取得してレビューを作成するために使用します`

### Step 6: 設定ファイルに情報を追加

`Obi/Config/AppleMusicConfig.swift` を作成（次のステップで自動作成されます）

---

## 4. 環境変数の設定（重要）

### .gitignoreに追加
APIキーなどの機密情報をGitHubにプッシュしないため、以下を `.gitignore` に追加：

```
# Supabase Config
Obi/Config/SupabaseConfig.swift

# Apple Music Config
Obi/Config/AppleMusicConfig.swift

# 環境変数
.env
*.xcconfig
```

### テンプレートファイルを作成
チーム開発のため、設定例ファイルを作成：

**SupabaseConfig.example.swift:**
```swift
enum SupabaseConfig {
    static let url = "YOUR_SUPABASE_URL"
    static let anonKey = "YOUR_SUPABASE_ANON_KEY"
}
```

---

## 5. ビルドとテスト

### ビルド
1. Xcodeでプロジェクトを開く
2. シミュレータを選択（iPhone 15 Pro推奨）
3. **⌘ + B** でビルド
4. エラーがないことを確認

### 実行
1. **⌘ + R** でアプリを実行
2. シミュレータでアプリが起動することを確認

---

## トラブルシューティング

### Supabase SDKが見つからない
```
error: no such module 'Supabase'
```

**解決策:**
1. Xcodeを再起動
2. `File → Packages → Reset Package Caches`
3. プロジェクトをクリーンビルド（⌘ + Shift + K）

### MusicKitの権限エラー
```
error: MusicKit authorization failed
```

**解決策:**
1. `Info.plist` に `NSAppleMusicUsageDescription` が追加されているか確認
2. シミュレータの「設定 → プライバシーとセキュリティ → メディアとApple Music」でアプリが許可されているか確認

### Supabase接続エラー
```
error: Failed to connect to Supabase
```

**解決策:**
1. `SupabaseConfig.swift` のURLとキーが正しいか確認
2. SupabaseダッシュボードでプロジェクトがActiveになっているか確認
3. インターネット接続を確認

---

## 次のステップ

セットアップが完了したら：

1. [FEATURE_SPEC.md](FEATURE_SPEC.md) で機能仕様を確認
2. 認証機能の実装から開始
3. Apple Music検索機能の実装
4. レビュー機能の実装

---

最終更新: 2026-03-14
