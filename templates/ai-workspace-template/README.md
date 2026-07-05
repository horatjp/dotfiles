# ai-workspace テンプレート

プロジェクトにAI協働基盤(`AGENTS.md` + `docs/ai/`)を導入するためのテンプレート。
Claude Code / Codex CLI / Gemini CLI など、AGENTS.md 系の指示ファイルを読む
CLIコーディングAI全般に対応する。

## 構成

```
AGENTS.md              # 薄い入口: セッション開始手順・安全ルール・記録の義務
docs/ai/
├── INDEX.md           # 目次=地図。どこに何があるか
├── STATUS.md          # 現在地。進行中の作業・次の一手
├── PROJECT.md         # プロジェクト概要・技術スタック・制約(安定情報)
├── RULES.md           # 書き込みルール・命名規則・テンプレート
├── decisions/         # 意思決定の記録(重要度はフロントマターの impact)
├── learnings.md       # 失敗と学び(再発防止)
├── research/          # 技術調査・バグ解決
├── references/        # 一次資料・URL
└── archive/           # 退避先
```

運用ルールはすべて展開先のリポジトリ内(`AGENTS.md` と `docs/ai/RULES.md`)に
自己完結するため、スキルや外部設定を持たないAIでも同じ運用が回る。

> **同期の注意**: このテンプレートは `claude/skills/project-bootstrap/assets/ai-workspace/`
> にも同梱している(スキルを単体コピーしても動くようにするため)。
> どちらかを変更したら、もう一方も同じ内容に更新すること。

## 導入手順

```bash
# 1. テンプレートを対象プロジェクトへコピー
#    (docs/ が既にあるプロジェクトでも二重ネストしないよう docs/ai を直接コピーする)
cp ai-workspace-template/AGENTS.md <project-root>/
mkdir -p <project-root>/docs
cp -R ai-workspace-template/docs/ai <project-root>/docs/

# 2. symlink を作成(Claude Code / Gemini CLI 用)
cd <project-root>
ln -s AGENTS.md CLAUDE.md
ln -s AGENTS.md GEMINI.md
```

3. AIセッションを開き、次のように指示する:

> docs/ai/PROJECT.md と STATUS.md を、私に質問しながら初期化して

ヒアリングと記入はAIの仕事。`docs/ai/` 配下は原則AIが書き、人間は書かない。

**注意**: 既存の `AGENTS.md` / `CLAUDE.md` があるプロジェクトでは上書きしないこと。
AIに両方を読ませて統合案を出させ、承認してから統合する。

## 運用の要点

- 新しいセッションは `AGENTS.md` → `INDEX.md` + `STATUS.md` + `learnings.md` の順に読んで再開する
- ビルド・テスト手順などプロジェクト固有の指示は `AGENTS.md` に追記する
  (`docs/ai/PROJECT.md` は概要・制約などの安定した背景情報のみ)
- 決定・調査・学びは会話中に都度書き込ませる(「後で書く」はさせない)
- 失敗したら「やり直せ」ではなく「原因を分析して learnings.md に残してから直して」と指示する
- セッションの終わりに「STATUS.md を更新して」と一声かけると次回の再開が確実になる
- 月1回程度「棚卸しして」と一声かける。superseded になった決定のアーカイブと、
  再検討条件が成立した決定の見直しをAIが提案する(手順は RULES.md)

## 関連テンプレート

複数エージェントの並列実行(GitHub Issues + worktree + 役割分離)を統制したい場合は
`../dev-agent-template/` を使う。**併用する場合は `docs/ai/` を知識層の正とし、
dev-agent-template 側の `knowledge/` は導入しない**(詳細は同テンプレートのREADME参照)。
