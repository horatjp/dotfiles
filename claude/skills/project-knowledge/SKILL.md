---
name: project-knowledge
description: >
  プロジェクトの意思決定・技術調査・バグ解決・参照資料・学びを記録・参照・更新する時に使用。
  「意思決定を残して」「決定記録に追加して」「PDRに追加して」「ナレッジ管理を始めて」
  「初期セットアップして」などのフレーズや、docs/decisions/・docs/knowledge/・docs/pdr/・
  knowledge/ 配下のファイルを扱う時。プロジェクトの既存方式を自動判定し、それに従う。
  旧 pdr-manager スキルの機能を統合済み。
---

# project-knowledge スキル

プロジェクトのナレッジ(意思決定・調査・参照資料・学び)の記録・整理ルール。
旧来の `knowledge/` 方式に加え、pdr-manager(`docs/pdr/` 方式)と
project-template 標準方式(`docs/decisions/`・`docs/knowledge/`)を統合した後継。

## 方式の判定(最初に必ず行う)

プロジェクトに以下が存在するかを上から順に確認し、最初に該当した方式に従う。
**方式を勝手に混在・新設しない。**

| 存在するもの | 方式 | ルール |
|---|---|---|
| `docs/decisions/`(project-template 由来) | 標準方式 | 本ファイルの「標準方式」節 |
| `docs/ai/` | ai-workspace 方式 | `docs/ai/RULES.md` に従う |
| `docs/pdr/` | PDR 方式 | `references/pdr.md` を読んで従う |
| `knowledge/` | knowledge 方式 | `references/knowledge-dir.md` を読んで従う |
| いずれも無い | 新規導入 | 下の「新規導入」節 |

複数が併存する場合は、どちらに書くかをユーザーに確認する。

## 新規導入

ナレッジ管理を始めたいプロジェクトには標準方式を提案する:

1. `docs/decisions/`・`docs/knowledge/` を作成する(必要になってから。空フォルダを先に量産しない)
2. 本格的なプロジェクト基盤(AGENTS.md・changes/・STATUS 等)ごと整えたい場合は
   [project-template](https://github.com/horatjp/project-template) の導入を提案する
3. 旧方式のプロジェクトを標準方式へ移行したい場合は project-template の `MIGRATION.md` に従う(移行は任意)

## 標準方式(project-template 準拠)

### 書き込みルーティング

「後で書く」はしない。会話中に都度書き込む。

| 何が起きたか | 書き先 |
|---|---|
| 方針・技術選定・設計・制約を決めた | `docs/decisions/YYYY-MM-DD-topic.md` |
| 技術を調査した / バグを解決した / 一次資料・URLを参照した | `docs/knowledge/topic-subtopic.md`(1件1ファイル) |
| AI自身の作業のしかたで失敗した | `docs/learnings.md`(ゲート: 根本原因特定・再発性・する/しないで書ける、の3条件すべて) |

既存ファイルと主題が同じなら新規作成せず既存を更新する。

### frontmatter(OKF 互換の方言)

decisions:

```yaml
---
type: decision
title: <決定の一言>
description: <一行要約。ファイルを開かずに関連判断できる粒度で>
status: stable          # draft | stable | deprecated
superseded_by:          # deprecated のとき必須
stale_after:            # 任意(YYYY-MM-DD)。時限性のある決定のみ
tags: []
generated:
  by: agent:<tool-name>@<role>   # 例: agent:claude-code@coder。人間は human:<id>
  at: YYYY-MM-DD
verified: []            # 空=未検証。書式: [{by: ..., at: YYYY-MM-DD}]
---
```

knowledge は `type: research | reference` で、他は同じ(reference は `stale_after` を特に推奨)。

本文の目安 — decision: 背景 / 決定と理由 / 検討した代替案 / 再検討の条件。
research: 調査背景 / 比較・評価 / 結論。バグ解決: 症状 / 原因 / 修正 / 再発防止のシグナル。
reference: URL / なぜ保存したか / 要点の抜き書き。

### 運用ルール

- 既存の決定を覆すときは新しい決定記録を起こし、その場で旧記録を
  `status: deprecated` + `superseded_by` にする(誤字・補足はそのまま編集)
- `verified` を付けられるのは `generated.by` と異なる `by` だけ(自己検証禁止)。
  本文の内容を変更したら既存の `verified` を削除する
- 読むときは `deprecated`・`stale_after` 超過を判断根拠にしない。不備があっても
  読み取りを止めず、問題は修正提案として報告する
- 日付は環境の現在日付を確認して書く。記憶から推測しない
- プロジェクト横断の知見はプロジェクト内に書かず、保存先をユーザーに確認する

### 報告

読み書きをサイレントで行わない。書き込みは個別に報告し
(「`docs/decisions/xxx.md` に書き込みました」)、読み込みはまとめて1行で報告する。
