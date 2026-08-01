---
name: project-knowledge
description: >
  プロジェクトの意思決定・技術調査・バグ解決・参照資料・学び・作業状態の記録・参照・更新に使用。
  「意思決定を残して」「決定記録(ADR・PDR)に追加して」「PDRに残して」「調査結果を残して」「学びを残して」
  「このURLを保存して」「棚卸しして」「ナレッジ管理を始めて」「引き継ぎを残して」などのフレーズや、
  docs/decisions/・docs/knowledge/・docs/learnings.md・docs/STATUS.md を扱う時。ユーザーの依頼が無くても、
  方針や技術選定を決めた直後・調査を終えた直後・バグの原因を特定した直後・
  作業が途中のままセッションを終える時にも使う。
  ただし project-template 導入済みプロジェクト(docs/decisions/_template.md がある)では
  使わない — そちらの AGENTS.md と _template.md に従う。
---

# project-knowledge スキル

プロジェクトのナレッジ(意思決定・調査・参照資料・学び)の記録・整理ルール。
[project-template](https://github.com/horatjp/project-template) と同じ方式の単体利用版。

## 書き込みルーティング

「後で書く」はしない。会話中・出来事の直後に都度書き込む。
ただしレビュー・調査など読み取りだけを求められた依頼では、勝手に書き込まず記録の作成を提案する。
書く前に既存ファイルをファイル名と `description` で走査し(全文は開かない)、
主題が同じものがあれば新規作成せず更新する(編集前に候補の本文を必ず読む。
ただし decisions の決定内容の変更は、更新ではなく下記運用ルールに従い新規記録で置き換える)。
置き場が無ければその時に作る。

| 何が起きたか | 書き先 | 内容 |
|---|---|---|
| 方針・技術選定・設計・制約を決めた | `docs/decisions/YYYY-MM-DD-topic.md` | 決定記録 =「なぜ」。**「採用しない」と決めた場合も、その決定を1件の記録として残す** |
| 技術を調査した / バグを解決した / 一次資料・URLを参照した | `docs/knowledge/topic-subtopic.md` | 1件1ファイル。調査の結論は書くが、**採用の決定は decisions へ分け、両者を相互にリンクする** |
| AI自身の作業のしかたで失敗した | `docs/learnings.md` | 下記ゲートを通過したもののみ |
| 作業が途中のままセッションを終える / 次回への引き継ぎがある | `docs/STATUS.md` | **上書き型の1枚**。常に最新の現在地だけを保つ |

learnings のゲート(3条件すべて「はい」のときのみ追記):
①根本原因を特定できた ②同じパターンが再発し得る ③次回の行動を「する/しない」で明記できる

仕様書・アーキテクチャ概要・セットアップ手順・Runbook など「現在の姿」を書く生きた
ドキュメントは**このスキルの対象外**。通常のドキュメントとして docs/ 配下に置き、
基盤ごと整えたい場合は後述の project-template 導入を提案する。

## frontmatter(decisions / knowledge のみ。learnings・STATUS には付けない)

```yaml
---
type: decision          # decisions/ は decision。knowledge/ は research(調査・バグ解決) | reference(一次資料・URL・外部仕様)
title: <一言>
description: <一行要約。ファイルを開かずに関連判断できる粒度で>
status: stable          # draft(承認待ち) | stable(現行) | deprecated(無効)
superseded_by:          # deprecated のとき必須。置き換えたファイル名
stale_after:            # 任意(YYYY-MM-DD)。reference は特に推奨(外部情報は腐る)
tags: []
generated:
  by: agent:<tool-name>@<role>   # 例: agent:claude-code@coder。人間は human:<id>。role 未指定なら @general
  at: YYYY-MM-DD
verified: []            # 空=未検証。書式: [{by: agent:<tool>@reviewer | human:<id>, at: YYYY-MM-DD}]
---
```

本文の目安 — decision: 背景 / 決定と理由 / 検討した代替案 / 影響範囲 / 再検討の条件。
research: 調査背景 / 比較・評価 / 結論。バグ解決: 症状 / 原因 / 修正 / 再発防止のシグナル。
reference: URL / なぜ保存したか / 要点の抜き書き。
learnings: `## YYYY-MM-DD: <一言>` + **Signal**(起きそうな状況)/ **Root Cause** / **Prevention**。
`docs/learnings.md` を新規作成するときは、ゲート3条件とこの書式を冒頭のHTMLコメントとして書き込む。
STATUS: 見出しは project-template と同じ「現在の目標 / 進行中 / 次の一手 / 保留・未解決 /
最終更新(日付・更新者)」。**追記せずファイル全体を上書きする**
(過去の状態は残さない — 履歴は git が持つ)。決めたこと・分かったことは STATUS に書かず
decisions / knowledge へ書き、STATUS からは要点とファイル名の参照だけにする。
引き継いだ作業が完了したら「次の一手」を「なし」へ更新し、古い引き継ぎを残さない。

## 運用ルール

- **承認フロー**: 重要な決定はまず `status: draft` で起こし、ユーザーの承認を得て `stable` にする
- **既存の決定の編集は、開始前にユーザーへ「更新か上書きか」を確認する**:
  誤字・てにをは・補足説明(決定は不変)→ 上書き(そのまま編集)/
  決定内容・status の変更 → 更新(新しい決定記録を起こし、旧を `status: deprecated` + `superseded_by` に)
- `verified` は**実際にレビューを実施した主体**だけが付ける。同じ tool-name は role・
  セッションが違っても本人(自己検証=不可)。架空の検証者を書かない。
  本文の内容を変更したら既存の `verified` を削除する(誤字修正は除く)
- 読むとき: `deprecated`・`stale_after` 超過は判断根拠にしない(超過を見つけたら
  更新か deprecated 化をユーザーに提案する)。`draft` や未検証
  (`verified` が空)の記録は参考扱いとし、重要な判断の根拠にする前に検証する。
  不備(リンク切れ・欠けたフィールド)があっても読み取りを止めず、修正提案として報告する
- `docs/learnings.md` が100行を超えたら、削除せず棚卸し(統合・整理・恒常ルール化)を
  ユーザーに提案する。学びを勝手に恒常ルールへ昇格しない(提案して承認を得る)
- 既存の決定が関わる領域を変更するときは、着手前に関連する decisions を確認する
- `docs/STATUS.md` があるプロジェクトで作業を始めるときは、まず STATUS を読んで現在地を把握する
- 日付は環境の現在日付を確認して書く。記憶から推測しない
- そのプロジェクトのコード・構成に依存しない汎用的な知見は、プロジェクト内に書かず
  保存先をユーザーに確認する

## 報告

読み書きをサイレントで行わない。書き込みは個別に報告し、読み込みはまとめて1行で報告する。

## 本格導入

記録だけでなくプロジェクト基盤ごと整えたい場合(AGENTS.md・変更スペック・STATUS 等)は
project-template の導入を提案する。
