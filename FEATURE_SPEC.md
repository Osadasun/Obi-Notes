# Obi Notes - 機能仕様書

音楽批評SNSアプリ「Obi Notes」の機能仕様

## コンセプト

**「音楽版Filmarks」**
- アルバム・楽曲のレビューと評価
- ユーザー間でのレビュー共有
- Apple Music APIとの連携
- ビジュアル重視のUI（ジャケット中心）

---

## マネタイズ戦略

### フェーズ1（最初の1年）
- 完全無料でユーザー獲得
- 質の高いレビューデータを蓄積

### フェーズ2（1年後〜）
1. **データ販売**（BtoB）
   - レコード会社・レーベル向けインサイト
   - 月額10-50万円

2. **アーティスト向けプラン**
   - 自分の音楽の分析ツール
   - 月額5千円〜5万円

### フェーズ3（2年後〜）
3. **一般ユーザー向けサブスク**（月額480円）
4. **イベント・チケット手数料**
5. **プレイリストキュレーション事業**

---

## Phase 1: MVP（最小機能版）

### 1. 認証機能

**実装内容：**
- Apple Sign In
- Google Sign In
- プロフィール設定
  - 名前
  - アイコン画像
  - 自己紹介

**技術：**
- バックエンド: Supabase Authentication
- ストレージ: Supabase Storage（アイコン画像）

---

### 2. 音楽検索機能

**実装内容：**
- Apple Music API統合
- アルバム検索
- 楽曲検索
- アーティスト検索

**表示情報：**
- アルバムアート
- タイトル
- アーティスト名
- リリース日
- ジャンル
- トラックリスト

**技術：**
- Apple Music API
- MusicKit for Swift

---

### 3. レビュー機能

**評価システム：**
- 星5段階評価
- 入力: 0.5刻み（0.5, 1.0, 1.5 ... 5.0）
- 表示: 平均は小数第一位まで（例: 4.2）

**レビュー内容：**
- テキストレビュー（任意、最大1000文字）
- 対象: アルバム or 楽曲
- 聴いた日付（デフォルト: 投稿日）
- 公開/非公開設定

**機能：**
- レビュー作成
- レビュー編集
- レビュー削除
- 下書き保存（オプション）

**データベース構造（Supabase PostgreSQL）：**
```sql
-- reviews テーブル
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  target_type TEXT CHECK (target_type IN ('album', 'track')) NOT NULL,
  target_id TEXT NOT NULL, -- Apple Music ID
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
```

---

### 4. ホーム画面（ジャケットグリッド型）

**レイアウト：**
- 縦スクロール
- セクション別表示
- 各セクションは横スクロール可能

**セクション構成：**

1. **最新のレビュー**
   - 全ユーザーの最新レビュー
   - 新しい順
   - 3列グリッド

2. **今週の人気アルバム**
   - レビュー数が多い
   - 評価が高い
   - 3列グリッド

3. **フォロー中のレビュー**（Phase 2で実装）
   - フォローしているユーザーのレビュー

**ジャケット表示：**
```
┌────────┐
│        │
│  🎵   │  ← アルバムアート
│        │
├────────┤
│ ★★★★☆ │  ← 評価
│ @user  │  ← ユーザー名
└────────┘
```

**タップ動作：**
- ジャケット → アルバム詳細ページ
- ユーザー名 → ユーザープロフィール

---

### 5. アルバム/楽曲 詳細ページ

**表示内容：**

```
┌─────────────────────────┐
│      大きなジャケット     │
│                         │
│ Album/Track Name        │
│ Artist Name             │
│ ★★★★☆ 4.2 (23件)      │
│                         │
│ [+ レビューを書く]       │
│ [リストに追加]           │
│                         │
│ ───────────────────     │
│ レビュー                 │
│                         │
│ 👤 @user1  ★★★★★ 5.0  │
│ "このアルバムは..."      │
│ 💬 2  ❤️ 5             │
│                         │
│ 👤 @user2  ★★★★☆ 4.5  │
│ "良いけど..."            │
│ 💬 0  ❤️ 2             │
└─────────────────────────┘
```

**機能：**
- Apple Music情報表示
- 平均評価の計算・表示
- レビュー一覧（新しい順/評価順）
- レビュー作成ボタン
- リストに追加ボタン

---

### 6. マイリスト機能

**デフォルトリスト：**
1. **聴いた** - 評価済みアルバム/楽曲
2. **聴きたい** - ウィッシュリスト
3. **お気に入り** - 星4以上（自動）

**カスタムリスト：**
- ユーザーが自由に作成
- リスト名（例: "2024年のベスト", "雨の日用"）
- 説明文（任意）
- 公開/非公開設定

**表示形式：**
- グリッドビュー（デフォルト）: 3列
- リストビュー: 1列、詳細情報付き

**並び替え：**
- 追加日順（新しい順/古い順）
- 評価順（高い順/低い順）
- アーティスト名順
- リリース日順

**データベース構造：**
```sql
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
CREATE INDEX idx_lists_user_id ON lists(user_id);
CREATE INDEX idx_list_items_list_id ON list_items(list_id);
```

---

### 7. SNSシェア機能

**シェアできるもの：**

#### A. 単一のレビュー
- アルバムジャケット
- 星評価
- レビューテキスト（抜粋 or 全文）
- ユーザー名
- アプリへのリンク

#### B. リスト全体
```
┌─────────────────────────────┐
│  私の2024年ベストアルバム10選  │
│                             │
│  🎵 🎵 🎵 🎵 🎵             │
│  🎵 🎵 🎵 🎵 🎵             │
│                             │
│  @username - Obi Notes      │
└─────────────────────────────┘
```

**実装方法：**
- SwiftUIで画像を生成
- UIGraphicsImageRenderer使用
- iOS標準のシェアシート（UIActivityViewController）

**シェア先：**
- Instagram
- X (Twitter)
- その他SNS
- 画像を保存

**カスタマイズ：**
- 背景色選択
- レイアウト選択（グリッド2x5, 3x4等）

---

### 8. マイページ（プロフィール）

**表示内容：**
```
┌─────────────────────────┐
│    👤 アイコン           │
│    ユーザー名            │
│    自己紹介              │
│                         │
│ レビュー: 85件           │
│ 平均評価: ★★★★☆ 4.2   │
│ リスト: 12個             │
│                         │
│ [プロフィール編集]       │
│                         │
│ ───────────────────     │
│ 📝 レビュー  📚 リスト  │
│                         │
│ ┌────┬────┬────┐       │
│ │ 🎵 │ 🎵 │ 🎵 │       │
│ └────┴────┴────┘       │
└─────────────────────────┘
```

**タブ：**
1. **レビュー** - 自分のレビュー一覧（グリッド）
2. **リスト** - 自分のリスト一覧

**統計：**
- 総レビュー数
- 平均評価
- リスト数
- 聴いたアルバム数（Phase 2: グラフ表示等）

---

### 9. タブバー構成

```
┌─────┬─────┬─────┬─────┐
│ 🏠  │ 🔍  │  +  │ 👤  │
│ホーム│ 検索 │レビュー│ マイ │
└─────┴─────┴─────┴─────┘
```

1. **ホーム** - ジャケットグリッド、タイムライン
2. **検索** - 音楽検索、発見
3. **レビュー作成** - モーダル表示
4. **マイページ** - プロフィール、設定

---

## Phase 2: 成長期機能

### ソーシャル機能
- フォロー/フォロワー
- いいね機能
- コメント機能
- 通知機能
- タイムラインフィルタリング

### 発見機能の強化
- ジャンル別ブラウジング
- トレンドアルバム
- おすすめユーザー

---

## Phase 3: 拡張機能

### データ分析
- 年間統計（Spotify Wrapped風）
- 詳細な聴取傾向分析
- ジャンル分布グラフ

### レコメンド
- AIによるおすすめ
- 類似ユーザーの発見
- 好みに合うアルバム提案

### その他
- ユーザーランキング
- バッジ・実績システム
- プレイリスト連携

---

## 技術スタック

### フロントエンド
- SwiftUI
- iOS 16.0+
- MusicKit for Swift

### バックエンド
- Supabase Authentication
- Supabase PostgreSQL Database
- Supabase Storage
- Supabase Edge Functions（オプション）

### API
- Apple Music API

### その他
- GitHub（バージョン管理）
- TestFlight（ベータテスト）

---

## データベース設計まとめ（Supabase PostgreSQL）

### テーブル構造

**profiles（Supabase auth.users の拡張）**
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  photo_url TEXT,
  bio TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**reviews**
```sql
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

  -- キャッシュ
  album_art TEXT,
  title TEXT NOT NULL,
  artist TEXT NOT NULL
);
```

**lists**
```sql
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
```

**list_items**
```sql
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
```

### 便利なビュー（データ分析用）

```sql
-- アルバム別の平均評価とレビュー数
CREATE VIEW album_stats AS
SELECT
  target_id,
  title,
  artist,
  AVG(rating) as avg_rating,
  COUNT(*) as review_count
FROM reviews
WHERE target_type = 'album' AND is_public = true
GROUP BY target_id, title, artist;

-- ユーザー別の統計
CREATE VIEW user_stats AS
SELECT
  user_id,
  COUNT(*) as total_reviews,
  AVG(rating) as avg_rating,
  COUNT(DISTINCT target_id) as unique_albums
FROM reviews
GROUP BY user_id;
```

---

## 次のステップ

1. Supabase プロジェクトのセットアップ
   - アカウント作成
   - プロジェクト作成
   - データベーススキーマの作成
2. Apple Music API の申請・セットアップ
   - Apple Developer Program 登録
   - MusicKit 識別子の作成
   - API キーの取得
3. SwiftUI プロジェクトの基本構造作成
   - MVVM アーキテクチャ
   - フォルダ構成
4. Supabase Swift SDK の統合
5. 認証機能の実装（Apple/Google Sign In）
6. 音楽検索機能の実装（Apple Music API）
7. レビュー機能の実装
8. ホーム画面の実装
9. マイリスト機能の実装
10. SNSシェア機能の実装
11. テスト・デバッグ
12. TestFlight配布

---

最終更新: 2026-03-14
