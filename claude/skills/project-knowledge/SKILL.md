---
name: project-knowledge
description: >
  プロジェクトの意思決定・技術調査・バグ解決・参照資料・学びを記録・参照・更新する時に使用。
  「意思決定を残して」「決定記録に追加して」「調査結果を残して」「ナレッジ管理を始めて」
  「初期セットアップして」などのフレーズや、docs/decisions/・docs/knowledge/ 配下の
  ファイルを扱う時。
---

# project-knowledge スキル

プロジェクトのナレッジ(意思決定・調査・参照資料・学び)の記録・整理ルール。
[project-template](https://github.com/horatjp/project-template) と同じ方式。

## 置き場所

無いものは必要になった時に作る(空フォルダを先に量産しない)。

| パス | 内容 |
|---|---|
| `docs/decisions/` | 決定記録 — 方針・技術選定・設計・制約の「なぜ」 |
| `docs/knowledge/` | 技術調査・バグ解決・一次資料(1件1ファイル、`type` で区別) |
| `docs/learnings.md` | AI自身の失敗と学び(100行上限) |

## 書き込みルーティング

「後で書く」はしない。会話中に都度書き込む。既存ファイルと主題が同じなら新規作成せず更新する。

| 何が起きたか | 書き先 |
|---|---|
| 方針・技術選定・設計・制約を決めた | `docs/decisions/YYYY-MM-DD-topic.md` |
| 技術を調査した / バグを解決した / 一次資料・URLを参照した | `docs/knowledge/topic-subtopic.md` |
| AI自身の作業のしかたで失敗した | `docs/learnings.md`(ゲート: ①根本原因を特定できた ②再発し得る ③「する/しない」で書ける、の3条件すべて) |

## frontmatter(OKF 互換の方言)

```yaml
---
type: decision          # decisions/ は decision。knowledge/ は research | reference
title: <一言>
description: <一行要約。ファイルを開かずに関連判断できる粒度で>
status: stable          # draft | stable | deprecated
superseded_by:          # deprecated のとき必須。置き換えたファイル名
stale_after:            # 任意(YYYY-MM-DD)。reference は特に推奨(外部情報は腐る)
tags: []
generated:
  by: agent:<tool-name>@<role>   # 例: agent:claude-code@coder。人間は human:<id>
  at: YYYY-MM-DD
verified: []            # 空=未検証。書式: [{by: ..., at: YYYY-MM-DD}]
---
```

本文の目安 — decision: 背景 / 決定と理由 / 検討した代替案 / 再検討の条件。
research: 調査背景 / 比較・評価 / 結論。バグ解決: 症状 / 原因 / 修正 / 再発防止のシグナル。
reference: URL / なぜ保存したか / 要点の抜き書き。

## 運用ルール

- 既存の決定を覆すときは新しい決定記録を起こし、その場で旧記録を
  `status: deprecated` + `superseded_by` にする(誤字・補足はそのまま編集)
- `verified` を付けられるのは `generated.by` と異なる `by` だけ(自己検証禁止)。
  本文の内容を変更したら既存の `verified` を削除する
- 読むときは `deprecated`・`stale_after` 超過を判断根拠にしない。不備があっても
  読み取りを止めず、問題は修正提案として報告する
- 日付は環境の現在日付を確認して書く。記憶から推測しない
- プロジェクト横断の知見はプロジェクト内に書かず、保存先をユーザーに確認する

## 報告

読み書きをサイレントで行わない。書き込みは個別に報告し
(「`docs/decisions/xxx.md` に書き込みました」)、読み込みはまとめて1行で報告する。

## 本格導入

記録だけでなくプロジェクト基盤ごと整えたい場合(AGENTS.md・変更スペック・STATUS 等)は
project-template の導入を提案する。
