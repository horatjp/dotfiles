---
name: git-commit
description: Gitコミットを作成する際のヘルパー。変更内容を分析し、Gitmoji付きのConventional Commits準拠のメッセージを生成します。ハンク単位での論理的な分割とリバート可能なコミットを推奨します。
---

# Gitコミットヘルパー

このスキルは、Gitコミットを作成する際に、変更内容を分析して適切なコミットメッセージを生成します。

## 基本原則

1. **Conventional Commitsに準拠**
2. **細粒度で独立してリバート可能なコミットを作成**
3. **ファイル単位ではなくハンク単位・論理的な単位に分割**
4. **Gitmojiで視覚的に分かりやすく**
5. **プロジェクトの言語に合わせたメッセージ（READMEから自動検出）**

## 使用方法

### 1. プロジェクトの言語を検出

- まず `README.md` または `README` ファイルを読み込む
- ファイルの主要言語を判定（日本語、英語など）
- コミットメッセージはその言語で作成

### 2. 現在の状態を確認

```bash
git status
git diff --staged
# ステージされた変更がない場合
git diff
```

### 3. 変更をハンク単位で分析

- `git add -p` の使用を推奨して、論理的な単位で分割
- 各ハンクが独立した論理的変更になっているか確認
- 無関係な変更は別のコミットに分離

### 4. コミットメッセージを生成

- 変更内容に最適なGitmojiを選択
- Conventional Commitsの型を決定
- 簡潔で明確な要約行を作成
- 必要に応じて詳細な説明を追加

## コミットメッセージの形式

### 基本形式（Conventional Commits + Gitmoji）

```
<gitmoji> <type>: <subject>

<body>

<footer>
```

**例:**
```
✨ feat: ユーザー認証機能を追加
🐛 fix: ログインフォームのバリデーションエラーを修正
♻️ refactor: データベース接続処理をモジュール化
```

## Gitmoji マッピング

### 最頻出

| Gitmoji | Code | Type | 説明 |
|---------|------|------|------|
| ✨ | :sparkles: | feat | 新機能の追加 |
| 🐛 | :bug: | fix | バグ修正 |
| 🚑 | :ambulance: | fix | 緊急の修正（ホットフィックス） |
| ♻️ | :recycle: | refactor | リファクタリング |
| ⚡️ | :zap: | perf | パフォーマンス改善 |
| 🎨 | :art: | style | コード構造/フォーマットの改善 |
| 📝 | :memo: | docs | ドキュメント追加・更新 |
| ✅ | :white_check_mark: | test | テスト追加・更新・合格 |
| 🔒️ | :lock: | fix | セキュリティ/プライバシー問題の修正 |
| 🔥 | :fire: | - | コード/ファイルの削除 |

### 依存関係

| Gitmoji | Code | Type | 説明 |
|---------|------|------|------|
| ➕ | :heavy_plus_sign: | build | 依存関係の追加 |
| ➖ | :heavy_minus_sign: | build | 依存関係の削除 |
| ⬆️ | :arrow_up: | build | 依存関係のアップグレード |
| ⬇️ | :arrow_down: | build | 依存関係のダウングレード |
| 📌 | :pushpin: | build | 依存関係を特定バージョンに固定 |

### UI/UX

| Gitmoji | Code | Type | 説明 |
|---------|------|------|------|
| 💄 | :lipstick: | style | UI/スタイルファイルの追加・更新 |
| 🚸 | :children_crossing: | - | UX/ユーザビリティの改善 |
| ♿️ | :wheelchair: | - | アクセシビリティの改善 |
| 📱 | :iphone: | - | レスポンシブデザイン対応 |
| 💫 | :dizzy: | - | アニメーション/トランジション追加・更新 |

### 設定/ビルド

| Gitmoji | Code | Type | 説明 |
|---------|------|------|------|
| 🔧 | :wrench: | chore | 設定ファイルの追加・更新 |
| 🔨 | :hammer: | chore | 開発スクリプトの追加・更新 |
| 👷 | :construction_worker: | ci | CIビルドシステムの追加・更新 |
| 💚 | :green_heart: | ci | CIビルドの修正 |
| 🚀 | :rocket: | - | デプロイ |

### データベース/ストレージ

| Gitmoji | Code | Type | 説明 |
|---------|------|------|------|
| 🗃️ | :card_file_box: | - | データベース関連の変更 |
| 🌱 | :seedling: | - | シードファイルの追加・更新 |

### コード品質

| Gitmoji | Code | Type | 説明 |
|---------|------|------|------|
| 🚨 | :rotating_light: | - | コンパイラ/linterの警告修正 |
| ⚰️ | :coffin: | - | デッドコードの削除 |
| 🗑️ | :wastebasket: | - | 非推奨コードのクリーンアップ |
| 💡 | :bulb: | - | ソースコードのコメント追加・更新 |
| 🏷️ | :label: | - | 型の追加・更新 |
| 🥅 | :goal_net: | - | エラーキャッチ |

### その他の重要なもの

| Gitmoji | Code | Type | 説明 |
|---------|------|------|------|
| 🎉 | :tada: | - | プロジェクト開始 |
| 🔖 | :bookmark: | - | リリース/バージョンタグ |
| 💥 | :boom: | - | 破壊的変更の導入 |
| ⏪ | :rewind: | revert | 変更の取り消し |
| 🔀 | :twisted_rightwards_arrows: | - | ブランチマージ |
| 📦 | :package: | build | コンパイルファイル/パッケージの追加・更新 |
| 👽️ | :alien: | - | 外部APIの変更による更新 |
| 🚚 | :truck: | - | リソースの移動/リネーム |
| 📄 | :page_facing_up: | - | ライセンスの追加・更新 |
| 🍱 | :bento: | - | アセットの追加・更新 |
| 🔐 | :closed_lock_with_key: | - | シークレットの追加・更新 |
| 🙈 | :see_no_evil: | - | .gitignoreファイルの追加・更新 |
| 📸 | :camera_flash: | - | スナップショットの追加・更新 |
| ⚗️ | :alembic: | - | 実験的な変更 |
| 🔍 | :mag: | - | SEOの改善 |
| 🚩 | :triangular_flag_on_post: | - | フィーチャーフラグの追加・更新・削除 |
| 🛂 | :passport_control: | - | 認可/ロール/パーミッション関連 |
| 🩹 | :adhesive_bandage: | fix | 重大でない問題の簡易修正 |
| 🧐 | :monocle_face: | - | データ探索/検査 |
| 🧪 | :test_tube: | test | 失敗するテストの追加 |
| 👔 | :necktie: | - | ビジネスロジックの追加・更新 |
| 🩺 | :stethoscope: | - | ヘルスチェックの追加・更新 |
| 🧱 | :bricks: | - | インフラ関連の変更 |
| 🧑‍💻 | :technologist: | - | 開発者体験の改善 |
| 💸 | :money_with_wings: | - | スポンサーシップ/マネタイズ関連 |
| 🧵 | :thread: | - | マルチスレッド/並行処理関連 |
| 🦺 | :safety_vest: | - | バリデーション関連 |
| ✏️ | :pencil2: | - | タイポ修正 |
| 🌐 | :globe_with_meridians: | - | 国際化/ローカライゼーション |
| 🚧 | :construction: | - | 作業中（WIP） |
| 🔊 | :loud_sound: | - | ログの追加・更新 |
| 🔇 | :mute: | - | ログの削除 |
| 👥 | :busts_in_silhouette: | - | コントリビューターの追加・更新 |
| 🏗️ | :building_construction: | - | アーキテクチャ変更 |
| 🤡 | :clown_face: | - | モック作成 |
| 🥚 | :egg: | - | イースターエッグの追加・更新 |
| 📈 | :chart_with_upwards_trend: | - | アナリティクス/トラッキングコードの追加・更新 |
| 💬 | :speech_balloon: | - | テキスト/リテラルの追加・更新 |
| ✈️ | :airplane: | - | オフラインサポートの改善 |

### 避けるべきもの（通常使用しない）

| Gitmoji | Code | 説明 |
|---------|------|------|
| 💩 | :poop: | 改善が必要な悪いコード |
| 🍻 | :beers: | 酔っ払ってコードを書く |

## ハンク単位でのコミット分割

### git add -p の活用

```bash
# インタラクティブにハンクを選択
git add -p <file>

# オプション:
# y - このハンクをステージ
# n - このハンクをスキップ
# s - このハンクを分割
# e - このハンクを手動編集
# q - 終了
```

### 分割の基準

1. **論理的な独立性**
   - 各コミットが独立して意味を持つ
   - 単独でリバート可能

2. **単一責任の原則**
   - 1つのコミットは1つの目的のみ
   - バグ修正とリファクタリングは別コミット
   - 新機能とコードフォーマットは別コミット

3. **テスト可能性**
   - 各コミット後にテストが通る状態を維持
   - ビルドが壊れない

4. **レビュー容易性**
   - レビュワーが理解しやすい粒度
   - diff が小さく明確

### 分割例

**❌ 悪い例（まとめすぎ）:**
```bash
# すべてを1つのコミットに
git add .
git commit -m "✨ feat: ユーザー機能追加とバグ修正と依存関係更新"
```

**✅ 良い例（適切に分割）:**
```bash
# 1. 依存関係の更新
git add package.json package-lock.json
git commit -m "⬆️ build: React を 18.2 から 18.3 にアップグレード"

# 2. バグ修正
git add -p src/components/LoginForm.tsx
git commit -m "🐛 fix: メールアドレス検証の正規表現を修正"

# 3. 新機能
git add -p src/components/UserProfile.tsx
git commit -m "✨ feat: ユーザープロフィール編集機能を追加"

# 4. テスト
git add src/components/__tests__/UserProfile.test.tsx
git commit -m "✅ test: ユーザープロフィール編集のテストを追加"
```

## 言語検出とメッセージ生成

### 手順

1. **README検出**
```bash
# README.md または README ファイルを読み込む
cat README.md 2>/dev/null || cat README 2>/dev/null
```

2. **言語判定**
   - 日本語文字（ひらがな、カタカナ、漢字）が多い → 日本語
   - それ以外 → 英語
   - 言語が不明な場合はデフォルトで英語

3. **メッセージ生成**
   - 検出した言語でコミットメッセージを作成
   - subjectとbodyの両方を適切な言語で

### 例

**日本語プロジェクト:**
```
✨ feat: ユーザー認証機能を追加

JWT トークンベースの認証システムを実装しました。
ログイン、ログアウト、トークンのリフレッシュ機能を含みます。
```

**英語プロジェクト:**
```
✨ feat: add user authentication feature

Implemented JWT token-based authentication system.
Includes login, logout, and token refresh functionality.
```

## ワークフロー例

```bash
# 1. READMEから言語を検出
cat README.md

# 2. 変更を確認
git status
git diff

# 3. ハンク単位で分割してステージング
git add -p src/auth.js
git add -p src/utils/jwt.js

# 4. ステージされた内容を確認
git diff --staged

# 5. Claudeに依頼
# 「この変更のコミットメッセージを作成して」
# または
# 「これらの変更を論理的な単位に分割してコミットして」

# 6. Claudeが実行すること:
#    - README から言語を検出
#    - 変更内容を分析
#    - 論理的な単位に分割
#    - 各単位に適切なGitmojiとメッセージを生成
#    - 順次コミットを実行
```

## ベストプラクティス

### 1. 原子性（Atomic Commits）

各コミットは：
- 独立して機能する
- 単独でリバート可能
- ビルド/テストが通る

### 2. 段階的なコミット

```bash
# 段階1: 準備（リファクタリング）
♻️ refactor: 認証ロジックを auth モジュールに抽出

# 段階2: 新機能の追加
✨ feat: JWT トークンベースの認証を実装

# 段階3: テスト
✅ test: 認証フローのテストを追加

# 段階4: ドキュメント
📝 docs: 認証システムのREADMEを更新
```

### 3. 意味のあるメッセージ

- 「何を」だけでなく「なぜ」も説明
- 技術的な詳細は body に
- issue や PR の参照を含める

### 4. Gitmojiの一貫性

- チーム内で同じGitmojiを同じ目的で使用
- 迷ったらもっとも一般的なものを選択
- プロジェクトの `.gitmoji` ルールがあれば優先

### 5. コミット前のチェックリスト

- [ ] 変更は論理的に独立しているか？
- [ ] リバートしても他のコミットに影響しないか？
- [ ] コミットメッセージは明確か？
- [ ] 適切なGitmojiが選択されているか？
- [ ] テストは通るか？
- [ ] linterの警告はないか？

## コミット実行

### 単一コミット

```bash
git commit -m "✨ feat: コミットメッセージ"
```

### 詳細な説明付き

```bash
git commit -m "$(cat <<'EOF'
✨ feat: ユーザー認証機能を追加

JWT トークンベースの認証システムを実装しました。

主な変更:
- ログイン/ログアウト機能
- トークンのリフレッシュ
- 認証ミドルウェア

Closes #42
EOF
)"
```

### 複数コミットの一括実行

Claudeが分析後、複数の論理的なコミットを提案した場合：

1. 各コミットの内容を確認
2. 承認後、順次実行
3. 各コミット後に状態を確認

## トラブルシューティング

### コミットが大きすぎる場合

```bash
# 最後のコミットを取り消してやり直し
git reset HEAD~1

# ハンク単位で再ステージング
git add -p
```

### 間違ったファイルをコミットした場合

```bash
# 最後のコミットを修正
git reset --soft HEAD~1
git restore --staged <不要なファイル>
git commit
```

### コミットメッセージを修正したい場合

```bash
# 最後のコミットメッセージを修正
git commit --amend -m "新しいメッセージ"
```
