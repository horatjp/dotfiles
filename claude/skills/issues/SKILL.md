---
name: issues
description: 個人タスクとプロジェクトISSUEを一元管理するスキル。ユーザーが「ISSUEを作って」「タスクを確認」などと指示した時、またはコード内のTODOコメントを発見した時に使用。
---

# Issues

個人タスクとプロジェクトISSUEを一元管理するスキルです。ISSUEは `.claude/skills/issues/issues/` に保存されます。

## 使用タイミング

### ユーザーからの指示
- 「ISSUEを作って」「タスクを作って」
- 「やることリストを見せて」「未完了のISSUEは？」
- 「このバグをISSUEにして」
- 「優先度が高いタスクは？」

### プロアクティブ（積極的な使用）
以下の場合は、ユーザーにISSUE作成を提案してください：
- 複雑な作業を開始する前（複数ステップ必要）
- 重要なバグや問題を発見した時
- 将来の作業が必要と判明した時
- 依存関係やブロッカーを発見した時
- コード内にTODOコメントを発見した時

## ディレクトリ構造

```
issues/
├── 001-setup-dev-environment.md
├── 002-fix-login-bug.md
├── 003-implement-dark-mode.md
└── .archive/                        # 完了ISSUEのアーカイブ（月別）
    └── 2025-01/
        └── 000-completed-issue.md
```

**ポイント**:
- フラットな構造（すべてのISSUEを `issues/` ディレクトリに配置）
- `project` フィールドや `tags` で分類
- 連番付きのkebab-case命名

## ISSUEの作成

### 1. 連番を決定

```bash
LAST_NUM=$(find issues -name "*.md" -type f 2>/dev/null | \
  sed 's/.*\/\([0-9]\+\)-.*/\1/' | sort -n | tail -1)
NEXT_NUM=$(printf "%03d" $((10#${LAST_NUM:-0} + 1)))
```

### 2. ファイル作成

必須front matterを含むファイルを作成：

```markdown
---
title: "ISSUEのタイトル"
created: 2025-01-09
status: todo
---

# ISSUEのタイトル

## 説明
詳細な説明をここに...

## タスク
- [ ] ステップ1
- [ ] ステップ2
```

### オプションのfront matterフィールド

- `type`: task/bug/feature/question/enhancement/chore
- `priority`: low/medium/high/urgent
- `due`: 期限（YYYY-MM-DD）
- `updated`: 最終更新日
- `tags`: 検索用タグの配列
- `project`: プロジェクト識別（personal, dotfiles, web-app など）
- `related`: 関連ファイル・リンクの配列
- `blocked_by`: ブロック関係
- `estimate`: 見積もり時間

### 3. ファイル例

#### 個人タスク例

```markdown
---
title: "Neovimのプラグイン設定を整理"
created: 2025-01-09
status: in-progress
type: chore
priority: medium
tags: [neovim, dotfiles, setup]
project: personal
estimate: 3h
---

# Neovimのプラグイン設定を整理

## 背景
プラグインが増えすぎて管理が煩雑になっている。lazy.nvimへの移行を検討。

## タスク
- [ ] 現在のプラグイン一覧を棚卸し
- [ ] 不要なプラグインを削除
- [ ] lazy.nvimのドキュメントを読む
- [ ] 段階的に移行

## メモ
- packer.nvimから移行予定
- 参考: https://github.com/folke/lazy.nvim
```

#### プロジェクトISSUE例

```markdown
---
title: "ユーザー認証のセッション切れ時にリダイレクトしない"
created: 2025-01-09
status: todo
type: bug
priority: high
project: web-app
tags: [auth, frontend, bug]
related:
  - src/middleware/auth.ts
  - src/components/LoginForm.tsx
due: 2025-01-15
---

# セッション切れ時のリダイレクト不具合

## 症状
ユーザーのセッションが切れた際、ログイン画面にリダイレクトされず、エラー画面が表示される。

## 再現手順
1. ログイン
2. 1時間待機（セッションタイムアウト）
3. 任意のページにアクセス
4. エラー画面が表示される（期待: ログイン画面へリダイレクト）

## 調査メモ
- auth.tsのmiddlewareでエラーハンドリングが不足
- 401エラーをキャッチしていない

## 解決策候補
- axios interceptorで401エラーをグローバルに処理
- リダイレクトロジックをauth middlewareに追加
```

## ISSUEの検索・一覧（Summary-First アプローチ）

### 1. すべてのISSUE一覧

```bash
rg --no-ignore --hidden '^title:' issues/
```

`--no-ignore --hidden` フラグは必須（issues ディレクトリは .gitignore 対象のため）

### 2. ステータスでフィルタリング

```bash
# TODO状態のISSUE
rg --no-ignore --hidden '^status: todo$' issues/ -l | \
  xargs rg --no-ignore --hidden '^title:'

# 作業中のISSUE
rg --no-ignore --hidden '^status: in-progress$' issues/ -l | \
  xargs rg --no-ignore --hidden '^title:'

# 完了したISSUE
rg --no-ignore --hidden '^status: done$' issues/ -l | \
  xargs rg --no-ignore --hidden '^title:'
```

### 3. 優先度でフィルタリング

```bash
# 高優先度ISSUE
rg --no-ignore --hidden '^priority: high$' issues/ -l | \
  xargs rg --no-ignore --hidden '^title:'

# 緊急ISSUE
rg --no-ignore --hidden '^priority: urgent$' issues/ -l | \
  xargs rg --no-ignore --hidden '^title:'
```

### 4. プロジェクトでフィルタリング

```bash
# 特定プロジェクトのISSUE
rg --no-ignore --hidden '^project: dotfiles$' issues/ -l | \
  xargs rg --no-ignore --hidden '^(title|status|priority):'

# 個人タスク
rg --no-ignore --hidden '^project: personal$' issues/ -l | \
  xargs rg --no-ignore --hidden '^title:'
```

### 5. タグで検索

```bash
rg --no-ignore --hidden '^tags:.*\[.*react.*\]' issues/ -i -l | \
  xargs rg --no-ignore --hidden '^title:'
```

### 6. 期限が近いISSUE

```bash
# 今日から7日以内
TODAY=$(date +%Y-%m-%d)
rg --no-ignore --hidden "^due: " issues/ | \
  awk -v today="$TODAY" '$2 >= today && $2 <= today+7'
```

### 7. 全文検索（必要な場合のみ）

```bash
rg --no-ignore --hidden '<キーワード>' issues/ -i
```

### 8. ファイルを読み込み

タイトルから該当ファイルを特定したら、Read toolで内容を確認。

## ISSUEの更新

### ステータス変更

1. ファイルを読み込み
2. Editツールでstatusフィールドを変更
3. updatedフィールドを追加・更新

### 完了とアーカイブ

```bash
# アーカイブディレクトリを作成
mkdir -p issues/.archive/$(date +%Y-%m)

# 完了ISSUEを移動
mv issues/001-issue.md issues/.archive/2025-01/
```

## コード内TODOコメントの処理

### 1. TODOコメントを検出

```bash
rg 'TODO|FIXME|XXX|HACK' --type-add 'code:*.{ts,tsx,js,jsx,py,go,rs}' \
  --type code -n -C 1
```

### 2. ユーザーに提案

「コード内にN件のTODOコメントを発見しました。ISSUEとして記録しますか？」

### 3. ISSUE作成

- `issues/` ディレクトリに作成
- `type: chore` または `type: bug`
- `related` にファイルパスと行番号を記録
- `project` フィールドで該当プロジェクトを指定

## ベストプラクティス

### ISSUEの粒度
- **適切な粒度**: 1-3時間で完了できる単位
- **大きすぎる場合**: サブタスクに分割（チェックリスト使用）
- **小さすぎる場合**: 関連ISSUEをまとめる

### 優先度の付け方
- `urgent`: 今すぐ対応が必要（本番障害など）
- `high`: 重要で早めに対応
- `medium`: 通常の優先度（デフォルト）
- `low`: 時間がある時に

### タグの使い方
- 技術スタック: `[react, typescript, nodejs]`
- 機能領域: `[auth, api, frontend]`
- 作業種別: `[refactoring, testing, documentation]`

### projectフィールドの使い方
- 個人タスク: `personal`
- プロジェクト別: プロジェクト名（`dotfiles`, `web-app`, `blog` など）
- これにより、プロジェクトごとにISSUEをフィルタリング可能

### ブロック関係の記録
依存関係がある場合は`blocked_by`に記録：
```yaml
blocked_by:
  - "003-setup-database.md"
  - "#external-api-access"
```

## 保存する内容

✅ 個人の学習タスク・設定作業
✅ プロジェクトのバグ・機能開発
✅ 調査・質問事項
✅ 将来の改善アイデア
✅ コード内TODOの正式記録

## 保存しない内容

❌ すでにGitHub ISSUEで管理されている内容（重複）
❌ 5分以内で終わるような些細なタスク
❌ 機密情報（パスワード、APIキーなど）

## 注意事項

- `issues/` ディレクトリは `.gitignore` で除外される（個人用のため）
- ファイル名は連番付きkebab-case形式
- ripgrep検索時は必ず `--no-ignore --hidden` フラグを使用
- Summary-Firstアプローチで効率的に検索
- 完了ISSUEは定期的にアーカイブ

## status値の定義

- `todo`: 未着手（デフォルト）
- `in-progress`: 作業中
- `done`: 完了
- `blocked`: ブロック中（依存関係待ちなど）
- `cancelled`: キャンセル（不要になった）

## type値の定義

- `task`: 一般的なタスク（デフォルト）
- `bug`: バグ修正
- `feature`: 新機能開発
- `enhancement`: 既存機能の改善
- `question`: 調査・質問
- `chore`: 雑務（設定変更、依存更新など）
