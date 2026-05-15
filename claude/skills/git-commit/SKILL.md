---
name: git-commit
description: Gitコミットを作成する際のヘルパー。変更内容を分析し、Gitmoji付きのConventional Commits準拠のメッセージを生成します。ハンク単位での論理的な分割とリバート可能なコミットを推奨します。
context: fork
---

# Gitコミットヘルパー

変更内容を分析して適切なコミットメッセージを生成し、コミットを実行する。

## 基本原則

1. **Conventional Commits準拠**
2. **ハンク単位・論理的な単位に分割し、独立してリバート可能なコミットを作成**
3. **Gitmojiで視覚的に分かりやすく**
4. **プロジェクトの言語に合わせたメッセージ（READMEから自動検出）**

## 実行手順

### 1. プロジェクトの言語を検出

```bash
cat README.md 2>/dev/null || cat README 2>/dev/null
```

- 日本語文字（ひらがな・カタカナ・漢字）が多い → 日本語
- それ以外 → 英語

### 2. 過去のコミットを参照

```bash
git log --oneline -10
```

- 使われているGitmojiのパターンを把握する
- コミットメッセージの粒度感・文体を合わせる
- プロジェクト固有の慣習（scope記法など）を確認する

### 3. 現在の状態を確認

```bash
git status
git diff --staged
# ステージされた変更がない場合
git diff
```

### 4. 変更をハンク単位で分析・分割

論理的に独立した単位ごとにコミットを分割する：

```bash
# インタラクティブにハンクを選択
git add -p <file>
```

**分割の判断基準：**
- 各コミットが単独で意味を持つ（単一責任）
- バグ修正とリファクタリングは別コミット
- 新機能とフォーマット修正は別コミット
- 各コミット後もビルド・テストが通る状態を維持

### 5. コミットメッセージを生成・実行

```bash
git commit -m "$(cat <<'EOF'
<gitmoji> <type>(<scope>): <subject>

<body（任意）>

<footer（任意）>
EOF
)"
```

## コミットメッセージの形式

```
<gitmoji> <type>: <subject>
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
| ✅ | :white_check_mark: | test | テスト追加・更新 |
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

### 設定/ビルド

| Gitmoji | Code | Type | 説明 |
|---------|------|------|------|
| 🔧 | :wrench: | chore | 設定ファイルの追加・更新 |
| 🔨 | :hammer: | chore | 開発スクリプトの追加・更新 |
| 👷 | :construction_worker: | ci | CIビルドシステムの追加・更新 |
| 💚 | :green_heart: | ci | CIビルドの修正 |
| 🚀 | :rocket: | - | デプロイ |

### コード品質

| Gitmoji | Code | Type | 説明 |
|---------|------|------|------|
| 🚨 | :rotating_light: | - | コンパイラ/linterの警告修正 |
| ⚰️ | :coffin: | - | デッドコードの削除 |
| 💡 | :bulb: | - | ソースコードのコメント追加・更新 |
| 🏷️ | :label: | - | 型の追加・更新 |
| 🩹 | :adhesive_bandage: | fix | 重大でない問題の簡易修正 |
| ✏️ | :pencil2: | - | タイポ修正 |

### その他

| Gitmoji | Code | Type | 説明 |
|---------|------|------|------|
| 🎉 | :tada: | - | プロジェクト開始 |
| 🔖 | :bookmark: | - | リリース/バージョンタグ |
| 💥 | :boom: | - | 破壊的変更の導入 |
| ⏪ | :rewind: | revert | 変更の取り消し |
| 🔀 | :twisted_rightwards_arrows: | - | ブランチマージ |
| 📦 | :package: | build | コンパイルファイル/パッケージの追加・更新 |
| 🚚 | :truck: | - | リソースの移動/リネーム |
| 🌱 | :seedling: | - | シードファイルの追加・更新 |
| 🗃️ | :card_file_box: | - | データベース関連の変更 |
| 🏗️ | :building_construction: | - | アーキテクチャ変更 |
| 🧱 | :bricks: | - | インフラ関連の変更 |
| 🙈 | :see_no_evil: | - | .gitignoreファイルの追加・更新 |
| 🔐 | :closed_lock_with_key: | - | シークレットの追加・更新 |
| 🚧 | :construction: | - | 作業中（WIP） |
| 🔊 | :loud_sound: | - | ログの追加・更新 |
| 🔇 | :mute: | - | ログの削除 |
| 🌐 | :globe_with_meridians: | - | 国際化/ローカライゼーション |
| ⚗️ | :alembic: | - | 実験的な変更 |

## 分割例

**悪い例（まとめすぎ）:**
```bash
git add .
git commit -m "✨ feat: ユーザー機能追加とバグ修正と依存関係更新"
```

**良い例（適切に分割）:**
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

## コミット前のチェックリスト

- [ ] 変更は論理的に独立しているか？
- [ ] リバートしても他のコミットに影響しないか？
- [ ] コミットメッセージは明確か？
- [ ] 適切なGitmojiが選択されているか？
- [ ] テストは通るか？

## トラブルシューティング

### コミットが大きすぎた場合

```bash
# 最後のコミットを取り消してやり直し（新しいコミットを作る）
git reset HEAD~1
git add -p
```

### 間違ったファイルをコミットした場合

```bash
# ステージングを戻して新しいコミットを作成
git reset --soft HEAD~1
git restore --staged <不要なファイル>
git commit -m "メッセージ"
```
