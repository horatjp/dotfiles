# knowledge 方式(knowledge/)のルール

<!-- 旧 project-knowledge スキルの内容。knowledge/ を運用中のプロジェクトで適用する -->

## 構成

```
knowledge/
├── decisions/      # 判断・選択・方針・制約
├── research/       # 技術調査・バグ解決
├── daily/          # 作業ログ(オプション)
├── references/     # 一次資料・URL集
├── archive/        # 廃止ファイルの退避先
└── mistakes.md     # AIのミス記録
```

## 書き込みルーティング

「後で書く」はしない。会話中に都度書き込む。

| 何が起きたか | 書き先 |
|---|---|
| A vs B で判断した・設計方針を決めた・制約を設けた | `decisions/` |
| 技術を調査・比較・評価した | `research/`(調査テンプレート) |
| バグ・問題を解決した | `research/`(バグ解決テンプレート) |
| 今日の作業ログ・次回やること | `daily/`(長いセッションの日のみ) |
| 参照したURL・仕様書・外部資料 | `references/` |
| ユーザーから訂正を受けた(3条件を満たす場合のみ) | `mistakes.md` |

**境界の判断**: 「調査して採用を決めた」場合は両方に書く(research/ に調査結果、decisions/ に選定理由)。

**docs/pdr/ が併存する場合**: 重要な意思決定(アーキテクチャ・技術選定・インフラ構成など)は
`references/pdr.md` のルールで `docs/pdr/` に記録し、`decisions/` には日々の軽い判断のみを書く。
`docs/pdr/` が存在しない場合はすべて `decisions/` に書く(勝手に `docs/pdr/` を作らない)。

**プロジェクト横断の知見**(他プロジェクトでも使える知識)が出たら `knowledge/` には書かず、
保存先をユーザーに確認する。

## ファイル命名規則

- **decisions**: `YYYY-MM-DD-topic.md`(例: `2026-05-18-database-choice.md`)
- **research**: `topic-subtopic.md`(例: `yfinance-rate-limit.md`)
- **daily**: `YYYY-MM-DD.md`
- **references**: `kebab-case-title.md`(例: `stripe-api-docs.md`)

## 書き込みフォーマット

共通フロントマター:

```markdown
---
date: YYYY-MM-DD
tags: [relevant, tags]
related: [decisions/2026-05-18-xxx.md]   # knowledge/ からの相対パス
---
```

research/ — 技術調査: `# <技術名>: <調査テーマ>` / 調査背景 / 比較・評価(表) / 結論 / 参考(URL + why_saved)。

research/ — バグ解決: `# <コンポーネント>: <症状の一言>` / 症状 / 原因 / 修正 / 再発防止。

references/: frontmatter に `why_saved` と `last_checked` を持ち、タイトル + URL + 必要なら要約。

## mistakes.md への追記ルール

以下3問に**すべて「はい」**と答えられる場合のみ追記:

1. ユーザーからの明示的な訂正か?(自分の気づきは「いいえ」)
2. 同じパターンが別の場面でも起こり得るか?(一度きりの偶発は「いいえ」)
3. 「する/しない」で次回の行動を明記できるか?(曖昧な反省は「いいえ」)

形式:

```markdown
## YYYY-MM-DD: <一言で何を間違えたか>
**Signal**: このミスが起きそうな状況・トリガー
**Root Cause**: なぜ間違えたか
**Prevention**: 次回から具体的に何をする/しない
```

## アーカイブ運用

- `daily/`: ユーザーから指示があったときのみ、前月以前を `archive/YYYY-MM/daily/` に退避する。
  未完了タスクは退避前に新しい daily へ転記する
- その他: 廃止・古くなったファイルは削除せず、**ユーザーの指示があったときのみ**
  `archive/YYYY-MM/` に退避する

## 報告・スタイル

- 書き込みは必ず個別に報告し、読み込みはまとめて1行で報告する(サイレント禁止)
- シンプルで読みやすく。既存ファイルのパターン・命名規則に合わせる
