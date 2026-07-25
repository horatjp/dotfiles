---
name: project-bootstrap
description: 新規システム・Webアプリ開発の計画立案とプロジェクト下地作りのワークフロー。ユーザーが「システムを作りたい」「Webアプリを開発したい」「プロジェクトを始めたい」「要件を整理して」「計画を立てて」など新しい開発プロジェクトの立ち上げを依頼したときは必ずこのスキルを使うこと。予約システム・在庫管理・タスク管理・社内ツール・会員制サイトなど具体的なアプリ名での依頼にも使う。このスキルの範囲はヒアリング・要件整理・スタック選定・設計・タスク分解・AI協働基盤(project-template のリポジトリ層)の展開まで — 実装はしない(実装は下地を引き継いだ別セッションが行う)。既存コードの修正や実装作業そのものには使わない。
---

# プロジェクト計画・下地作りスキル

新規プロジェクトの立ち上げ時に、ユーザーへのヒアリングから始めて
「別のAIセッションがすぐ実装を始められる下地」を作るワークフロー。

**このスキルの成果物は動くコードではない。** 成果物は次の3点:

1. **合意済みの計画** — 要件・スタック・設計(ユーザーと1つずつ確認済み)
2. **AI協働基盤** — [project-template](https://github.com/horatjp/project-template) のリポジトリ層(`AGENTS.md` + `docs/` + `changes/`)
3. **実装スペック** — 会話履歴を知らないAIが着手できる `changes/initial-build/`

実装を求められても、このスキルの中ではコードを書かない。下地を完成させたうえで、
新しいセッション(または実装用AI)に引き継ぐよう案内する(フェーズ6参照)。

## ワークフロー全体像

```
0. 前提確認 → 1. ヒアリング → 2. スタック・デプロイ先選定 → 3. 設計 → 4. 下地展開 → 5. タスク分解 → 6. 引き継ぎ
```

## 0. 前提確認

- 対象に既に project-template 構成(`docs/decisions/_template.md` がある)がある場合:
  下地を作り直さない。`docs/STATUS.md` を読み、計画のやり直し・追加計画として
  該当フェーズ(1〜3, 5)だけを行い、結果は既存のルールに従って記録する
- プロジェクト全体(議事録・資料・複数リポジトリ)を管理したい場合は、リポジトリ単体の
  下地ではなく project-template のワークスペースごと導入することを提案する
  (`gh repo create <name> --template horatjp/project-template --private --clone`)
- 旧構成(`docs/ai/`・`knowledge/`・`docs/pdr/`)のプロジェクトでは下地を作り直さず、
  既存ルールに従う。移行を求められたら project-template の `MIGRATION.md` に従う
- 既存の `AGENTS.md` / `CLAUDE.md` があるプロジェクトでは上書きしない。
  フェーズ4で統合案を提示して承認を得る

## 1. ヒアリング(このスキルの中心)

`references/hearing.md` を読んでから始める。進め方の原則・質問領域・記録の仕方は
すべて hearing.md に従う(project-template の hearing スキルと同じ方法論。
両方が使える環境ではどちらを読んでもよい)。

hearing.md のチェックリスト全項目が「ユーザーの回答」または「ユーザーが承認した提案」で
埋まるまで、フェーズ2に進まない。

## 2. スタック・デプロイ先選定

`references/stack-selection.md` を読む。**デプロイ先はスタックと同時に決める**
(デプロイ先の制約がスタック選定を左右するため。特にCloudflare)。

候補と理由を示してユーザーの合意を取る。選定理由(候補・比較・決め手)は
フェーズ4の展開後に `docs/decisions/` へ決定記録として書く。

## 3. 設計

**DB設計を先に、API設計をその後に。** `references/design.md` を読んでから着手する。成果物
(いずれも「生きた文書」— 以後、変更が実装されたら常に現在形に保つ):

- `docs/schema.md` — エンティティ定義とリレーション
- `docs/api.md` — エンドポイント一覧(パス、メソッド、リクエスト/レスポンス概形、認可要件)
- `docs/rbac.md` — ロール×操作マトリクス(**ロール分離がある場合のみ**)

設計のユーザーへの提示と合意は design.md 末尾の「設計レビュー」に従う。

## 4. 下地展開(project-template リポジトリ層)

既存の `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` がある場合はコマンドを実行せず、
統合案を提示して承認を得てから統合する。無い場合のみ実行する:

```bash
tmp=$(mktemp -d)
gh repo clone horatjp/project-template "$tmp" -- --depth 1
cp -R "$tmp/templates/repo/." <project-root>/
rm -rf "$tmp"
```

展開後、ここまでの成果を書き込む:

- `docs/PROJECT.md` — 目的・スタック・制約(変わらない背景のみ)
- `docs/requirements.md` — ヒアリング結果(承認済み要件の正典。書式は hearing.md)
- `docs/schema.md` / `docs/api.md`(+ rbac.md)— フェーズ3の成果物
- `docs/decisions/` — スタック・デプロイ先の決定記録、設計上の主要判断、
  ヒアリングで「仮案+再検討の条件」とした項目(書式は `docs/decisions/_template.md`)
- `.claude/rules/` — `assets/handoff/` の実装規約をコピーし、各ファイル先頭に
  `paths` frontmatter を付ける(例: implementation.md → `"src/**"`、
  test-deploy.md → `"tests/**"`、admin-user-patterns.md → 管理画面のパス。
  スタックに合わせて glob と中身を調整する)
- `docs/STATUS.md` — 「現在の目標」のみ記入する。「次の一手」はまだ書かない
  (スペックが存在しないうちに書くと、存在しないファイルを指す引き継ぎになる)

## 5. タスク分解(changes/initial-build/)

初回実装は1つの change として `changes/initial-build/` に作る(書式は `changes/_template/`):

- `proposal.md` — 要件の要約とスコープ・やらないこと。承認欄には requirements.md を
  ユーザーが最終確認した事実(日付・発言要旨)を記入する
- `design.md` — 実装方針と、`docs/schema.md`・`docs/api.md` への参照
- `tasks.md` — 実装順に分解したチェックリスト。順序は依存の向きに従う:
  1. プロジェクト初期化 + スキーマ + マイグレーション + シード
  2. 認証基盤(必要な場合)+ ルート保護
  3. APIエンドポイント(コアのユースケースから)
  4. 画面(APIが動いてから)

各タスクは「実装AIの1セッションで完了する粒度(目安: 生成コード数百行以内)」
「テスト可能な検証」を満たすこと。「ちゃんと動く」は検証ではない。

作り終えたら `docs/STATUS.md` の「次の一手」を
「changes/initial-build/tasks.md のタスク1から実装開始」に更新する。

## 6. 引き継ぎ(完了条件)

終了前にセルフチェックする:

- [ ] `docs/requirements.md` の全項目がユーザー確認済み(推測で埋めた項目がない)
- [ ] `docs/schema.md` / `docs/api.md`(+ rbac.md)にユーザーの合意がある
- [ ] project-template リポジトリ層が展開され、PROJECT.md / STATUS.md が記入済み
- [ ] `docs/decisions/` にスタック・デプロイ先の決定記録がある
- [ ] `.claude/rules/` に実装規約が paths つきで置かれている
- [ ] `changes/initial-build/` だけで、会話履歴を知らないAIが実装を始められる

最後にユーザーへ引き継ぎ方法を案内する:

> 下地ができました。実装は新しいAIセッションで
> 「docs/STATUS.md を読んで、changes/initial-build/tasks.md から進めて」と指示してください。

## 参照ファイル

| ファイル | いつ読むか |
|---|---|
| `references/hearing.md` | フェーズ1の開始前(必読) |
| `references/stack-selection.md` | フェーズ2 |
| `references/design.md` | フェーズ3の着手前 |
| `assets/handoff/` | フェーズ4で `.claude/rules/` へコピーする実装規約 |

AI協働基盤の実体は project-template リポジトリ(展開時に取得)。このスキルは複製を持たない。
