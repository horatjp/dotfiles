---
name: git-commit-message
description: Gitコミットメッセージ作成専用。差分を要約し、Gitmoji付きConventional Commits形式のメッセージ本文のみを生成する。
---

# Gitコミットメッセージ生成（Copilot用）

## 目的

ステージ済み（または提示された）差分から、1つのコミットに対するコミットメッセージを生成する。

## 基本原則

1. **Conventional Commits に準拠**
2. **細粒度で独立してリバート可能なコミット** を前提に書く
3. **論理的な変更単位** を意識して要約する（ファイル単位ではなく変更内容ベース）
4. **Gitmoji で視覚的に分かりやすく**
5. **プロジェクトの言語** に合わせる（README.md を参照し、日本語文字が多ければ日本語、それ以外は英語）
6. **過去のコミット** を参照して粒度・文体・慣習を合わせる

## 出力ルール（最重要）

- 出力は **コミットメッセージ本文のみ**（解説、手順、コマンド、前置き、Markdownの見出し等は出力しない）
- 既定で **1件** のメッセージを生成する（複数コミット前提の提案や分割手順は出力しない）
- フォーマットは **Gitmoji + Conventional Commits**

## フォーマット

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

## 生成の観点（内部手順）

1. 差分から「主目的」を 1 つに要約（何を変えたか）
2. `type` を決める（変更の性質）
3. `scope` を付けるか判断（範囲が明確なときだけ）
4. `subject` を作る（短く具体的に）
5. `body` / `footer` は必要な場合だけ追加（理由・影響・互換性・参照）

## 例

```
✨ feat: ユーザー認証機能を追加
```

```
🐛 fix(api): nullレスポンス時にクラッシュする問題を修正

- 空配列を返すようにして呼び出し側の分岐を単純化

Refs: #123
```
