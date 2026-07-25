# dev-agent-template

複数AIエージェント(Claude Code / Codex等)でプログラム開発を進めるための
Skill化 + GitHub Issues管理 + worktree並列実行 + 自動改善ループのテンプレート一式です。

## 構成

```
.
├── AGENTS.md                     ← 全エージェント共通の運用ルール(まず読む)
├── .claude/skills/                ← 業務ごとのSkill定義
│   ├── code-review/               ← verifier用: レビュー観点
│   ├── api-design/                ← builder用: API設計規約
│   ├── test-writing/              ← builder用: テスト作成基準・自動リトライループ
│   └── deploy-checklist/          ← verifier用: マージ/デプロイ前チェック
│       └── learnings/             ← 各Skillに1つずつ。学びを1エントリ1ファイルで蓄積
│                                     (書式は learnings/README.md 参照)
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── task.md                ← 通常の実装タスク用
│   │   └── integration.md         ← 統合(fan-in)タスク用
│   └── workflows/
│       └── check-dependencies.yml ← Issueのclose/reopen時に依存を同期(イベント駆動)
├── scripts/
│   ├── setup-labels.sh            ← 運用に必要なラベルを一括作成(最初に1回実行)
│   ├── check-blocked.sh           ← 依存Issueの完了チェック(cron/Actions両対応・冪等)
│   ├── spawn-worktree.sh          ← Issueをclaimしてworktreeとブランチを自動作成
│   ├── cleanup-worktree.sh        ← closeされたIssueのworktree・ブランチを掃除
│   └── prune-learnings.md         ← learningsの月次棚卸し手順(エージェント向け指示書)
└── knowledge/
    ├── decisions/                 ← プロジェクト全体の決定事項
    └── research/                  ← 調査・比較検討の記録
```

## 使い方

### 0. 前提・初期セットアップ

- `gh` (GitHub CLI) がインストール・認証済みであること: `gh auth login`
- リポジトリはこのテンプレートをベースに作成 or 既存リポジトリにこの構成をコピー
- **symlinkを作成する**: `ln -s AGENTS.md CLAUDE.md && ln -s AGENTS.md GEMINI.md`
  (Codex CLI等は `AGENTS.md` を読みますが、Claude Code / Gemini CLI は
  `CLAUDE.md` / `GEMINI.md` を読むため)
- **ラベルを作成する(必須)**: `./scripts/setup-labels.sh`
  (todo / blocked / in-progress / needs-human に加え、`.claude/skills/` 配下から
  検出した `skill/<name>` ラベルが作成されます。Skillを追加したら再実行してください)
- **ブランチ保護を設定する(強く推奨)**: mainへの直接pushを禁止し、PR+approve必須にする。
  verifier(レビュー役)を別のGitHubアカウント/トークンで動かすと、
  「PR作成者は自己承認できない」というGitHubの制約がそのまま
  builder/verifier分離の機械的な強制装置になります。

### 1. タスクを分解してIssue化

```bash
gh issue create --title "認証API実装" --label "todo,skill/api-design"
gh issue create --title "ログイン画面実装" --label "todo"
gh issue create --title "結合・E2Eテスト" --label "blocked" \
  --body "Depends on: #1, #2"
```

`.github/ISSUE_TEMPLATE/task.md` と `integration.md` を使うと入力が楽になります
(GitHub上で「New Issue」を選ぶとテンプレートが選べます)。
担当範囲(触ってよいパスのglob)を本文に必ず書いてください。

### 2. 独立したタスクは並列でworktree実行

```bash
./scripts/spawn-worktree.sh 1   # 認証API実装用のworktreeを作成
./scripts/spawn-worktree.sh 2   # ログイン画面実装用のworktreeを作成
```

spawn時にIssueへ `in-progress` ラベルとassigneeが自動で付き、
他のエージェントが同じIssueを掴めなくなります(claim)。

それぞれのworktreeでbuilderエージェント(Claude Code等)を起動し、担当Issueの実装を進めます。
tmuxのpane/windowで1worktree=1エージェントを割り当てる運用が扱いやすいです。

### 3. 依存関係の自動解消

以下のどちらか(または両方)を設定してください。スクリプトは冪等なので併用しても安全です。

**A. cronで定期チェック(シンプル・確実)**
```bash
crontab -e
# 5分おきにチェック
*/5 * * * * cd /path/to/repo && ./scripts/check-blocked.sh >> /var/log/check-blocked.log 2>&1
```

**B. GitHub Actionsでイベント駆動(リアルタイム)**
`.github/workflows/check-dependencies.yml` がそのまま使えます。追加設定は不要です
(Actionsのデフォルト `GITHUB_TOKEN` で動作します。プライベートリポジトリでも動きます)。

依存Issueが**再オープン**された場合は、todoに進んでいた統合Issueが自動で `blocked` に戻ります。
既に着手済みだった場合は人間が継続/破棄を判断してください(AGENTS.md 6節)。

### 4. 完了・レビュー

builderが実装を終えたら、PRを作成します。**PR本文に必ず `Closes #<Issue番号>` を書いてください。**

`code-review` Skillの観点でverifier(別コンテキストのエージェント)にレビューさせ、
承認が出たらPRをマージします。**Issueはマージで自動closeされます。手動で
`gh issue close` しないでください** — このテンプレートでは「close = コードがmainに入った」を
不変条件にしており、統合(fan-in)タスクはそれを前提に `origin/main` から分岐します。

統合Issueは依存Issueが全てcloseされると自動的に `blocked` → `todo` に変わり、
着手可能になります。統合作業の最後には `deploy-checklist` Skillの全項目を確認してください。

### 5. 掃除

```bash
./scripts/cleanup-worktree.sh          # 削除候補を確認
./scripts/cleanup-worktree.sh --force  # 実際に削除(worktreeと不要ブランチ)
```

未コミット変更が残っているworktreeは `--force` でも削除されません(データ消失防止)。

### 6. 月次の棚卸し

`scripts/prune-learnings.md` の指示に沿って、Claude Codeのheadlessモード等で
`learnings/` の整理を月次実行してください。整理結果はPRとして提出され、
scribe(または人間)のレビューを経てmainに反映されます。

## カスタマイズのポイント

- `.claude/skills/` 配下のSKILL.mdはプロジェクトの実態に合わせて書き換えてください
  (テンプレートのままでは汎用的すぎます)。ただし運用開始後の変更は
  AGENTS.md 6節のエスカレーション条件(人間の承認)に従ってください
- GitHubのネイティブなIssue dependencies / sub-issuesが使える環境なら、
  本文パース(`Depends on:`)をそちらに置き換えるとより堅牢になります
- 事業やプロジェクトが複数ある場合、Skillの共通部分だけ別リポジトリに切り出して
  git submoduleやsparse-checkoutで共有する運用も可能です
- **docs/ai/ 方式(旧 ai-workspace-template)導入済みのプロジェクトと併用する場合**は、
  `docs/ai/` を知識層の正とし、このテンプレートの `knowledge/` はコピーしません
  (decisions/researchは `docs/ai/RULES.md` の書式で `docs/ai/` 配下へ)。
  各Skillの `learnings/` は並列worktree対応(1エントリ1ファイル)のためそのまま使います。
  AGENTS.mdは両テンプレートで役割が異なるため、AIに両方を読ませて統合してください
- 秘密情報(APIキー、顧客情報等)は `knowledge/` やSkillファイルに直接書かないこと。
  `.gitignore` で除外したローカルファイルか、環境変数・Secretsで管理してください
