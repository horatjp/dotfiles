---
name: project-knowledge
description: "Knowledge management rules for the project-local `knowledge/` directory. Use this skill whenever (1) the user requests initial setup of project knowledge (e.g. '初期セットアップして', 'ナレッジ管理を始めて'), (2) creating, writing to, or organizing files in knowledge/decisions/, knowledge/research/, knowledge/daily/, knowledge/references/, knowledge/archive/, or knowledge/mistakes.md, (3) deciding where to file a new piece of project-specific knowledge, or (4) archiving outdated knowledge files."
---

# project-knowledge スキル

プロジェクトローカルの `knowledge/` ディレクトリへのナレッジ書き込み・整理ルール。
プロジェクトルートの `CLAUDE.md` で本スキルが参照されている場合に適用する。

---

## 1. 初期セットアップ（初回のみ）

「初期セットアップして」「ナレッジ管理を始めて」と言われたら以下を作成:

```
knowledge/
├── decisions/      # 判断・選択・方針・制約
├── research/       # 技術調査・バグ解決
├── daily/          # 作業ログ（オプション）
├── references/     # 一次資料・URL集
├── archive/        # 廃止ファイルの退避先
└── mistakes.md     # AIのミス記録
```

空フォルダには `.gitkeep` を置く。セットアップ後、ユーザーに構造と各役割を伝え、`knowledge/PROJECT.md` にプロジェクト概要を書くよう提案する。

---

## 2. 書き込みルーティング

「後で書く」はしない。会話中に都度書き込む。

| 何が起きたか | 書き先 |
|---|---|
| A vs B で判断した・設計方針を決めた・制約を設けた | `decisions/` |
| 技術を調査・比較・評価した | `research/` （調査テンプレート） |
| バグ・問題を解決した | `research/` （バグ解決テンプレート） |
| 今日の作業ログ・次回やること | `daily/`（長いセッションの日のみ） |
| 参照したURL・仕様書・外部資料 | `references/` |
| ユーザーから訂正を受けた（3条件を満たす場合のみ） | `mistakes.md` |

**境界の判断**: 「調査して採用を決めた」場合は両方に書く（research/ に調査結果、decisions/ に選定理由）。

**プロジェクト横断の知見**（他プロジェクトでも使える知識）が出たら `knowledge/` には書かず、ユーザーに確認する:「共通ナレッジ置き場（例: `~/knowledge/`）に保存しますか？」→ 「はい」なら書き先をユーザーに指定してもらい、その場所に書く。

---

## 3. ファイル命名規則

- **decisions**: `YYYY-MM-DD-topic.md`（例: `2026-05-18-database-choice.md`）
- **research**: `topic-subtopic.md`（例: `yfinance-rate-limit.md`、`auth-token-expiry-bug.md`）
- **daily**: `YYYY-MM-DD.md`
- **references**: `kebab-case-title.md`（例: `stripe-api-docs.md`）

---

## 4. 書き込みフォーマット

### 共通フロントマター

```markdown
---
date: YYYY-MM-DD
tags: [relevant, tags]
related: [decisions/2026-05-18-xxx.md]   # knowledge/ からの相対パス
---
```

### research/ — 技術調査テンプレート

```markdown
---
date: YYYY-MM-DD
tags: [...]
related: []
---

# <ライブラリ/技術名>: <調査テーマ>

## 調査背景
なぜ調べたか（1-2行）

## 比較・評価
| 選択肢 | 長所 | 短所 |
|---|---|---|

## 結論
採用した/しなかった結論と理由

## 参考
- URL (why_saved: ...)
```

### research/ — バグ解決テンプレート

```markdown
---
date: YYYY-MM-DD
tags: [bug, ...]
related: []
---

# <コンポーネント>: <症状の一言>

## 症状
再現手順・エラーメッセージ

## 原因
根本原因

## 修正
具体的な対処（コードスニペット可）

## 再発防止
次回このパターンに気づくためのシグナル
```

### references/ フォーマット

```markdown
---
date: YYYY-MM-DD
why_saved: <なぜ保存したか1行>
last_checked: YYYY-MM-DD
---

# <タイトル>

URL: <url>

<必要なら要約や引用>
```

---

## 5. `mistakes.md` への追記ルール

以下3問に**すべて「はい」**と答えられる場合のみ追記:

1. ユーザーからの明示的な訂正か？（自分の気づきは「いいえ」）
2. 同じパターンが別の場面でも起こり得るか？（一度きりの偶発は「いいえ」）
3. 「する/しない」で次回の行動を明記できるか？（曖昧な反省は「いいえ」）

形式:

```markdown
## YYYY-MM-DD: <一言で何を間違えたか>
**Signal**: このミスが起きそうな状況・トリガー
**Root Cause**: なぜ間違えたか
**Prevention**: 次回から具体的に何をする/しない
```

---

## 6. `daily/` のアーカイブ

翌月1日に前月の `daily/` ファイルを `knowledge/archive/YYYY-MM/daily/` に退避する。  
ただし**ユーザーの明示的な指示があった場合のみ実行**する（自律的にアーカイブしない）。

月をまたいで未完了のタスクは、アーカイブ前に新しい `daily/YYYY-MM-DD.md` に転記する。

---

## 7. アーカイブ運用

廃止・古くなったファイルは削除せず、**ユーザーの指示があったときのみ** `knowledge/archive/YYYY-MM/` に退避する。

```
knowledge/decisions/2025-12-01-old-api.md
  → knowledge/archive/2026-05/decisions/2025-12-01-old-api.md
```

---

## 8. 報告

`knowledge/` を読み書きしたら必ずユーザーに伝える:

- 「`knowledge/decisions/xxx.md` を読みました」
- 「`knowledge/research/xxx.md` に書き込みました」

サイレントで読み書きしない。

---

## 9. 作業スタイル

- シンプルで読みやすいものを優先する。不要な装飾・冗長な説明は省く。
- 既存ファイルのパターン・命名規則に合わせる。

---

## プロジェクトへの導入方法

`templates/CLAUDE.md` をプロジェクトルートにコピーして使う:

```bash
cp <skill-dir>/templates/CLAUDE.md <project-root>/CLAUDE.md
```

初回セッションで「初期セットアップして」と伝えると `knowledge/` ディレクトリ一式が作成される。
