---
name: git-commit-message
description: Gitコミットメッセージ作成専用。差分を要約し、Gitmoji付きConventional Commits形式のメッセージ本文のみを生成する。
---

# Gitコミットメッセージ生成（Copilot用）

ステージ済み（または提示された）差分から、1つのコミットに対するコミットメッセージ本文のみを生成する。

## 基本原則

1. **Conventional Commits に準拠**
2. **論理的な変更単位を意識して要約する**（ファイル単位ではなく変更内容ベース、独立してリバート可能なコミットを前提に書く）
3. **Gitmoji で視覚的に分かりやすく**
4. **プロジェクトの言語に合わせる**（README.md を参照し、日本語文字が多ければ日本語、それ以外は英語）
5. **過去のコミットを参照**して粒度・文体・慣習を合わせる

## 出力ルール（最重要）

- 出力は **コミットメッセージ本文のみ**（解説、手順、コマンド、前置き、Markdownの見出し等は出力しない）
- 既定で **1件** のメッセージを生成する（複数コミット前提の提案や分割手順は出力しない）
- フォーマットは **Gitmoji + Conventional Commits**

## 生成手順

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

### 3. 差分を確認

```bash
git diff --staged
# ステージされた変更がない場合
git diff
```

### 4. 変更の「主目的」を1つに要約する

- 論理的に独立した変更単位で捉える（ファイル単位ではなく変更内容ベース）
- "差分を読めばわかること" の繰り返しは避ける

### 5. type・scope・gitmoji を決定する

- `type`: 下記「type の選び方」から選ぶ
- `scope`: 変更範囲が明確なときだけ付ける（例: `auth`, `ui`, `deps`）
- `gitmoji`: 下記「Gitmoji マッピング」から type に対応するものを選ぶ

### 6. コミットメッセージ本文を生成する

下記フォーマット・規約に従い、本文のみを出力する。

## コミットメッセージの形式

```
<gitmoji> <type>(<scope>)?: <subject>

<body>

<footer>
```

### subject の規約

- 何をしたかが一読でわかる具体性（「更新」「修正」だけにしない）
- 末尾に `.` や `。` を付けない
- 可能なら 72 文字以内（長い場合は言い換えて短くする）

### body の規約（必要なときだけ）

- 「何を/なぜ」を 1〜5 行で簡潔に補足
- 箇条書きは `- ` を使う
- "差分を読めばわかること" の繰り返しは避ける

### footer の規約（必要なときだけ）

- 破壊的変更がある場合: `BREAKING CHANGE: ...`
- Issue/PR 参照が必要な場合: `Refs: #123` / `Closes: #123`

## type の選び方（Conventional Commits）

| type | 使う場面 |
|---|---|
| feat | 新機能 |
| fix | バグ修正 |
| refactor | 振る舞いを変えない内部改善 |
| perf | パフォーマンス改善 |
| docs | ドキュメント変更 |
| test | テスト追加/修正 |
| build | ビルド/依存関係/パッケージ |
| ci | CI設定 |
| chore | 雑務（生成物以外の保守、設定の小変更など） |
| style | フォーマット、空白、並び替え等（挙動不変） |
| revert | リバート |

## Gitmoji マッピング

注: `Type` が `-` のものは、変更内容に応じて最適な Conventional Commits の `type` を選ぶ（迷ったら `chore`）

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

## scope（任意）

- 変更範囲が明確なときだけ付ける（例: `auth`, `ui`, `deps`, `nvim`）
- 命名は短く・一貫して（kebab-case 推奨）

## 例

```
✨ feat: ユーザー認証機能を追加
```

```
🐛 fix(api): nullレスポンス時にクラッシュする問題を修正

- 空配列を返すようにして呼び出し側の分岐を単純化

Refs: #123
```
