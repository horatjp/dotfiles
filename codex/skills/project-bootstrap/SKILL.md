---
name: project-bootstrap
description: 新規システム・Webアプリ開発の計画立案とプロジェクト下地作りのワークフロー。ユーザーが「システムを作りたい」「Webアプリを開発したい」「プロジェクトを始めたい」「要件を整理して」「計画を立てて」など新しい開発プロジェクトの立ち上げを依頼したときは必ずこのスキルを使うこと。予約システム・在庫管理・タスク管理・社内ツール・会員制サイトなど具体的なアプリ名での依頼にも使う。このスキルの範囲はヒアリング・要件整理・スタック選定・設計・タスク分解・AI協働基盤(docs/ai/)の展開まで — 実装はしない(実装は下地を引き継いだ別セッションが行う)。既存コードの修正や実装作業そのものには使わない。
---

# プロジェクト計画・下地作りスキル

新規プロジェクトの立ち上げ時に、ユーザーへのヒアリングから始めて
「別のAIセッションがすぐ実装を始められる下地」を作るワークフロー。

**このスキルの成果物は動くコードではない。** 成果物は次の3点:

1. **合意済みの計画** — 要件・スタック・設計(ユーザーと1つずつ確認済み)
2. **AI協働基盤** — `AGENTS.md` + `docs/ai/`(ai-workspace テンプレート)
3. **実装タスク指示書** — どのAIツールでも着手できる `tasks/NNN-*.md`

実装を求められても、このスキルの中ではコードを書かない。下地を完成させたうえで、
新しいセッション(または実装用AI)に引き継ぐよう案内する(フェーズ6参照)。

## ワークフロー全体像

```
0. 前提確認 → 1. ヒアリング → 2. スタック・デプロイ先選定 → 3. 設計 → 4. 下地展開 → 5. タスク分解 → 6. 引き継ぎ
```

## 0. 前提確認

- 対象プロジェクトに既に `docs/ai/` がある場合: このスキルで下地を作り直さない。
  `docs/ai/STATUS.md` と `INDEX.md` を読み、計画のやり直し・追加計画として
  該当フェーズ(1〜3, 5)だけを行い、結果は既存の `docs/ai/` のルールに従って記録する
- 既存の `AGENTS.md` / `CLAUDE.md` があるプロジェクトでは上書きしない。
  フェーズ4で統合案を提示して承認を得る

## 1. ヒアリング(このスキルの中心)

`references/hearing.md` を読んでから始める。進め方の原則・質問領域・記録の仕方は
すべて hearing.md に従う(ここに要約は置かない — 二重管理を避けるため)。

hearing.md のチェックリスト全項目が「ユーザーの回答」または「ユーザーが承認した提案」で
埋まるまで、フェーズ2に進まない。

## 2. スタック・デプロイ先選定

`references/stack-selection.md` を読む。**デプロイ先はスタックと同時に決める**
(デプロイ先の制約がスタック選定を左右するため。特にCloudflare)。

候補と理由を示してユーザーの合意を取る。決定の記録は stack-selection.md 末尾の
「選定結果の記録」に従う(迷わなかった場合でも必須。フェーズ4の展開時にまとめて書いてよい)。

## 3. 設計

**DB設計を先に、API設計をその後に。** `references/design.md` を読んでから着手する。成果物:

- `docs/schema.md` — エンティティ定義とリレーション
- `docs/api.md` — エンドポイント一覧(パス、メソッド、リクエスト/レスポンス概形、認可要件)
- `docs/rbac.md` — ロール×操作マトリクス(**ロール分離がある場合のみ**)

設計のユーザーへの提示と合意は design.md 末尾の「設計レビュー」に従う。

## 4. 下地展開(ai-workspace テンプレート)

まず展開先を確認する。**`<project-root>` に AGENTS.md / CLAUDE.md / GEMINI.md の
いずれかが既にある場合は、以下のコマンドを実行しない** — 既存内容とテンプレートの
両方を読んで統合案を提示し、承認を得てから統合する(symlink 構成にするかも含めて確認)。

どれも存在しない場合のみ実行する(symlink はリンク作成先をパスで指定しているため
cwd に依存しない。`<skill-dir>` / `<project-root>` は絶対パスに置き換える):

```bash
cp <skill-dir>/assets/ai-workspace/AGENTS.md <project-root>/AGENTS.md
cat <skill-dir>/assets/agents-md-append.md >> <project-root>/AGENTS.md
mkdir -p <project-root>/docs
cp -R <skill-dir>/assets/ai-workspace/docs/ai <project-root>/docs/
ln -s AGENTS.md <project-root>/CLAUDE.md
ln -s AGENTS.md <project-root>/GEMINI.md
```

統合パスを取った場合も、`assets/agents-md-append.md` の実装ルールセクションは
必ず AGENTS.md に含める(実装セッションが読む唯一の入口のため)。

展開後、ここまでの計画内容を書き込む(書式は `docs/ai/RULES.md` に従う):

- `docs/ai/PROJECT.md` — 目的・スタック・制約(ヒアリング結果から)
- `docs/ai/decisions/` — スタック・デプロイ先の決定記録、設計上の主要判断
- `docs/requirements.md` / `docs/schema.md` / `docs/api.md`(+ rbac.md)— フェーズ1〜3の成果物
- `docs/ai/references/` — `assets/handoff/` の実装規約
  (implementation.md / test-deploy.md、ロール分離・管理画面があるなら
  admin-user-patterns.md も)をコピーし、INDEX.md の個別ノートに追記する
- `docs/ai/INDEX.md` — さらに次のセクションを追記し、docs/ai/ の外にある
  設計ドキュメントと tasks/ を必ず地図に載せる:

  ```markdown
  ## docs/ai/ の外(プロジェクトルート基準)

  | パス | 内容 | いつ読むか |
  |---|---|---|
  | docs/requirements.md | 要件(ユーザー確認済み) | 実装タスク着手前 |
  | docs/schema.md, docs/api.md | 合意済みの設計。変更が承認されたら必ず更新する | 実装タスク着手前 |
  | tasks/ | 実装タスク指示書(進め方は AGENTS.md「実装タスクの進め方」) | タスク受け取り時 |
  ```

  (rbac.md を作ったプロジェクトでは design の行に含める)
- `docs/ai/STATUS.md` — 現在の目標のみ記入する。「次の一手」はまだ書かない
  (タスクが存在しないうちに「タスク001から実装開始」と書くと、中断時に
  存在しないファイルを指す引き継ぎになる — フェーズ5の最後に書く)

## 5. タスク分解

`references/task-breakdown.md` に従い、実装作業を `tasks/NNN-短い題名.md` の
指示書に分解する。実装順序は依存の向きに従う:

1. プロジェクト初期化 + スキーマ + マイグレーション + シード
2. 認証基盤(必要な場合)+ ルート保護
3. APIエンドポイント(コアのユースケースから)
4. 画面(APIが動いてから)

各タスクは「実装AIの1セッションで完了する粒度」「テスト可能な受け入れ条件」
「スコープ外の明記」を満たすこと。

タスクを作り終えたら、`docs/ai/STATUS.md` の「次の一手」を
「tasks/001 から実装開始」に更新する(フェーズ4で保留した項目)。

## 6. 引き継ぎ(完了条件)

終了前にセルフチェックする:

- [ ] `docs/requirements.md` の全項目がユーザー確認済み(推測で埋めた項目がない)
- [ ] `docs/schema.md` / `docs/api.md`(+ rbac.md)にユーザーの合意がある
- [ ] `AGENTS.md` + `docs/ai/` が展開され、PROJECT.md / STATUS.md / INDEX.md が記入済み
- [ ] `AGENTS.md` に実装ルール(`assets/agents-md-append.md` の内容)が含まれている
- [ ] `docs/ai/decisions/` にスタック・デプロイ先の決定記録がある
- [ ] `docs/ai/references/` の実装規約と、設計ドキュメント・`tasks/` が INDEX.md から辿れる
- [ ] `tasks/` の指示書だけで、会話履歴を知らないAIが実装を始められる

最後にユーザーへ引き継ぎ方法を案内する:

> 下地ができました。実装は新しいAIセッションで
> 「docs/ai/STATUS.md を読んで、tasks/001 から進めて」と指示してください。

## 参照ファイル

| ファイル | いつ読むか |
|---|---|
| `references/hearing.md` | フェーズ1の開始前(必読) |
| `references/stack-selection.md` | フェーズ2 |
| `references/design.md` | フェーズ3の着手前 |
| `references/task-breakdown.md` | フェーズ5 |
| `assets/ai-workspace/` | フェーズ4で展開するテンプレート(読むのではなくコピーする) |
| `assets/agents-md-append.md` | フェーズ4で展開先 AGENTS.md の末尾に追記する実装ルール |
| `assets/handoff/` | フェーズ4で `docs/ai/references/` へコピーする実装規約 |

`assets/ai-workspace/` は `templates/ai-workspace-template`(dotfiles)のコピー。
どちらかを変更したら、もう一方も同じ内容に更新すること。
