# Supabase セットアップガイド

Obi Notes アプリ用のSupabaseバックエンドのセットアップ手順

---

## 1. Supabaseプロジェクトの作成

### 1-1. アカウント作成
1. https://supabase.com にアクセス
2. 「Start your project」をクリック
3. GitHubアカウントでサインアップ（推奨）

### 1-2. プロジェクト作成
1. 「New Project」をクリック
2. 以下を入力：
   - **Name**: `obi-notes`
   - **Database Password**: 強力なパスワードを生成・保存
   - **Region**: `Northeast Asia (Tokyo)` を選択（日本から近い）
   - **Pricing Plan**: `Free` でOK
3. 「Create new project」をクリック
4. プロジェクトの準備完了を待つ（2-3分）

---

## 2. データベーススキーマの作成

### 2-1. SQL Editorを開く
1. 左サイドバーから「SQL Editor」をクリック
2. 「New query」をクリック

### 2-2. テーブル作成

以下のSQLを実行してテーブルを作成します：

```sql
-- profiles テーブル（ユーザープロフィール）
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  photo_url TEXT,
  bio TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- RLS（Row Level Security）を有効化
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ポリシー: 誰でも読める
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

-- ポリシー: 自分のプロフィールのみ更新可能
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- ポリシー: 自分のプロフィールのみ挿入可能
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

---

-- reviews テーブル
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  target_type TEXT CHECK (target_type IN ('album', 'track')) NOT NULL,
  target_id TEXT NOT NULL,
  rating NUMERIC(2,1) CHECK (rating >= 0.5 AND rating <= 5.0) NOT NULL,
  text TEXT,
  listened_date TIMESTAMP NOT NULL,
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  -- Apple Music データのキャッシュ
  album_art TEXT,
  title TEXT NOT NULL,
  artist TEXT NOT NULL
);

-- インデックス
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_target ON reviews(target_type, target_id);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);

-- RLS有効化
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- ポリシー: 公開レビューは誰でも読める
CREATE POLICY "Public reviews are viewable by everyone"
  ON reviews FOR SELECT
  USING (is_public = true OR auth.uid() = user_id);

-- ポリシー: 認証ユーザーはレビューを作成可能
CREATE POLICY "Authenticated users can create reviews"
  ON reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ポリシー: 自分のレビューのみ更新可能
CREATE POLICY "Users can update own reviews"
  ON reviews FOR UPDATE
  USING (auth.uid() = user_id);

-- ポリシー: 自分のレビューのみ削除可能
CREATE POLICY "Users can delete own reviews"
  ON reviews FOR DELETE
  USING (auth.uid() = user_id);

---

-- lists テーブル
CREATE TABLE lists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT true,
  type TEXT CHECK (type IN ('default', 'custom')) NOT NULL,
  default_type TEXT CHECK (default_type IN ('listened', 'wishlist', 'favorite')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- インデックス
CREATE INDEX idx_lists_user_id ON lists(user_id);

-- RLS有効化
ALTER TABLE lists ENABLE ROW LEVEL SECURITY;

-- ポリシー: 公開リストは誰でも読める
CREATE POLICY "Public lists are viewable by everyone"
  ON lists FOR SELECT
  USING (is_public = true OR auth.uid() = user_id);

-- ポリシー: 認証ユーザーはリストを作成可能
CREATE POLICY "Authenticated users can create lists"
  ON lists FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ポリシー: 自分のリストのみ更新可能
CREATE POLICY "Users can update own lists"
  ON lists FOR UPDATE
  USING (auth.uid() = user_id);

-- ポリシー: 自分のリストのみ削除可能
CREATE POLICY "Users can delete own lists"
  ON lists FOR DELETE
  USING (auth.uid() = user_id);

---

-- list_items テーブル
CREATE TABLE list_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  list_id UUID REFERENCES lists(id) ON DELETE CASCADE NOT NULL,
  target_type TEXT CHECK (target_type IN ('album', 'track')) NOT NULL,
  target_id TEXT NOT NULL,
  added_at TIMESTAMP DEFAULT NOW(),

  -- キャッシュ
  album_art TEXT,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  user_rating NUMERIC(2,1)
);

-- インデックス
CREATE INDEX idx_list_items_list_id ON list_items(list_id);

-- RLS有効化
ALTER TABLE list_items ENABLE ROW LEVEL SECURITY;

-- ポリシー: リストが見える人はアイテムも見える
CREATE POLICY "List items viewable if list is viewable"
  ON list_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM lists
      WHERE lists.id = list_items.list_id
      AND (lists.is_public = true OR lists.user_id = auth.uid())
    )
  );

-- ポリシー: リストのオーナーはアイテムを追加可能
CREATE POLICY "List owners can insert items"
  ON list_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM lists
      WHERE lists.id = list_items.list_id
      AND lists.user_id = auth.uid()
    )
  );

-- ポリシー: リストのオーナーはアイテムを削除可能
CREATE POLICY "List owners can delete items"
  ON list_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM lists
      WHERE lists.id = list_items.list_id
      AND lists.user_id = auth.uid()
    )
  );

---

-- 便利なビュー: アルバム別統計
CREATE VIEW album_stats AS
SELECT
  target_id,
  title,
  artist,
  album_art,
  AVG(rating)::NUMERIC(2,1) as avg_rating,
  COUNT(*) as review_count
FROM reviews
WHERE target_type = 'album' AND is_public = true
GROUP BY target_id, title, artist, album_art;

-- 便利なビュー: ユーザー別統計
CREATE VIEW user_stats AS
SELECT
  user_id,
  COUNT(*) as total_reviews,
  AVG(rating)::NUMERIC(2,1) as avg_rating,
  COUNT(DISTINCT target_id) as unique_albums
FROM reviews
GROUP BY user_id;

---

-- トリガー: updated_at を自動更新
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_reviews_updated_at
  BEFORE UPDATE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

---

-- 新規ユーザー登録時に自動でプロフィールを作成
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, photo_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

### 2-3. SQLを実行
1. 上記のSQLをコピー
2. SQL Editorに貼り付け
3. 「Run」をクリック
4. エラーがないことを確認

---

## 3. 認証設定

### 3-1. Apple Sign Inの設定

1. 左サイドバーから「Authentication」→「Providers」をクリック
2. 「Apple」を探して「Enable」
3. Apple Developer Consoleで設定が必要：
   - https://developer.apple.com にアクセス
   - 「Certificates, Identifiers & Profiles」
   - 「Identifiers」→「+」ボタン
   - 「Services IDs」を選択
   - Supabaseのコールバック URL を設定：
     `https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback`

### 3-2. Google Sign Inの設定

1. 「Authentication」→「Providers」で「Google」を探して「Enable」
2. Google Cloud Consoleで設定が必要：
   - https://console.cloud.google.com
   - OAuth 2.0 クライアント ID を作成
   - コールバック URL を設定：
     `https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback`

---

## 4. ストレージ設定（プロフィール画像用）

### 4-1. バケット作成
1. 左サイドバーから「Storage」をクリック
2. 「Create a new bucket」をクリック
3. 以下を入力：
   - **Name**: `avatars`
   - **Public bucket**: チェックを入れる（誰でも画像を見られる）
4. 「Create bucket」をクリック

### 4-2. ストレージポリシー設定
1. 作成した`avatars`バケットをクリック
2. 「Policies」タブをクリック
3. 以下のポリシーを追加：

```sql
-- 誰でも画像を見られる
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- 認証ユーザーは自分の画像をアップロード可能
CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- 認証ユーザーは自分の画像を更新可能
CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- 認証ユーザーは自分の画像を削除可能
CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

---

## 5. APIキーの取得

### 5-1. プロジェクト設定
1. 左サイドバーから「Settings」→「API」をクリック
2. 以下の情報をコピーして安全に保存：
   - **Project URL**: `https://[YOUR-PROJECT-REF].supabase.co`
   - **anon public key**: `eyJ...`（公開用キー）
   - **service_role key**: `eyJ...`（管理用キー、アプリには使わない）

### 5-2. Xcodeプロジェクトに設定
後でSwiftUIプロジェクトに以下を追加します：

```swift
// Config.swift
enum SupabaseConfig {
    static let url = "https://[YOUR-PROJECT-REF].supabase.co"
    static let anonKey = "eyJ..."
}
```

**重要:** これらの値を`.gitignore`に追加して、GitHubにプッシュしないこと！

---

## 6. Swift SDKのインストール

### 6-1. Swift Package Manager
1. Xcodeでプロジェクトを開く
2. 「File」→「Add Package Dependencies...」
3. 以下のURLを入力：
   ```
   https://github.com/supabase/supabase-swift
   ```
4. 「Add Package」をクリック
5. 以下を選択：
   - Supabase
   - Realtime（オプション、リアルタイム機能用）
   - PostgREST
   - Storage

---

## 7. 初期データの投入（オプション）

テスト用のデータを入れる場合：

```sql
-- テストユーザー（認証後に手動で追加）
-- テストレビュー
INSERT INTO reviews (
  user_id,
  target_type,
  target_id,
  rating,
  text,
  listened_date,
  title,
  artist,
  album_art
) VALUES (
  '[USER-UUID]',
  'album',
  '1234567890',
  4.5,
  'テストレビューです',
  NOW(),
  'Test Album',
  'Test Artist',
  'https://example.com/artwork.jpg'
);
```

---

## 8. セキュリティチェックリスト

- [ ] RLS（Row Level Security）が全テーブルで有効
- [ ] 各テーブルに適切なポリシーが設定されている
- [ ] `service_role` キーはアプリに含めない
- [ ] APIキーを`.gitignore`に追加
- [ ] ストレージポリシーが適切に設定されている

---

## 9. データベース管理

### 9-1. バックアップ
- Freeプランでは自動バックアップなし
- 定期的に手動でエクスポート推奨
- 「Database」→「Backups」から実行

### 9-2. データのエクスポート
```sql
-- CSV形式でエクスポート
COPY (SELECT * FROM reviews) TO STDOUT WITH CSV HEADER;
```

---

## トラブルシューティング

### エラー: "new row violates row-level security policy"
- RLSポリシーを確認
- 認証状態を確認（`auth.uid()`が正しく取得できているか）

### エラー: "permission denied for table"
- RLSが有効になっているか確認
- 適切なポリシーが設定されているか確認

### 接続エラー
- Project URLが正しいか確認
- anon keyが正しいか確認
- ネットワーク接続を確認

---

## 参考リンク

- Supabase公式ドキュメント: https://supabase.com/docs
- Supabase Swift SDK: https://github.com/supabase/supabase-swift
- PostgreSQL ドキュメント: https://www.postgresql.org/docs/

---

最終更新: 2026-03-14
