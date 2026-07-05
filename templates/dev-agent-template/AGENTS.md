# プロジェクト運用ルール(AGENTS.md)

このファイルはプロジェクトに参加する全エージェント(Claude Code / Codex / その他CLIエージェント)が
起動時に読み込む前提のルールです。人間が読んでも分かるように書いています。
AGENTS.md を直接読まないツール向けに、`CLAUDE.md` / `GEMINI.md` はこのファイルへの
symlinkとして作成してください(手順はREADMEの初期セットアップ参照)。

## 1. 役割の基本方針

- **planner**: Issueを分解し、依存関係を設計する。実装はしない。
- **builder**: 割り当てられたIssue(worktree)の実装のみを行う。
- **verifier**: builderの実装をレビューする。実装コードは書かず、指摘と承認/却下のみ行う。
- **scribe**: 決定事項・学びを `knowledge/` および各Skillの `learnings/` に記録し、
  learnings追記PRのレビュアーを務める。

同一エージェントが複数役割を兼任してもよいが、**verifierだけは必ず別コンテキスト(別セッション)で行う**こと。
自分が書いたコードを自分でレビューさせない。

この分離はルールだけでなく仕組みでも強制する(セットアップ時に人間が設定):

- mainブランチにブランチ保護をかけ、PR必須+approve必須にする
- 可能ならverifierは別のGitHubアカウント/トークンで動かす
  (GitHubの「PR作成者は自己承認できない」制約が機械的な強制装置になる)

## 2. タスクの単位

- 1つの実装タスク = 1つのGitHub Issue = 1つのgit worktree = 1ブランチ = 1 PR
- Issueには必ず `label: skill/<skill-name>` を付け、どのSkillを参照すべきか明示する
- 担当範囲はIssue本文に**パスのglob**で明記する(例: `src/api/auth/**`)。範囲外のファイルは変更しない
- 依存関係がある場合は Issue本文に `Depends on: #123, #124` の形式で明記する
  (この行は `scripts/check-blocked.sh` が自動パースする。フォーマット厳守)

## 3. Issueのライフサイクル(ラベルの意味)

```
blocked → todo → in-progress → (PRマージで自動close)
   ↑______________|      ※依存Issueが再オープンされたら自動でblockedに戻る
```

- **blocked**: 依存Issueの完了待ち。`check-blocked.sh` が自動で `todo` に付け替える
- **todo**: 着手可能。まだ誰もclaimしていない
- **in-progress**: エージェントが着手中。`spawn-worktree.sh` が自動で付与+assignする
- **needs-human**: エスカレーション中。人間の判断が出るまで当該Issueの自動処理を止める

**closeの意味を「対応PRがmainにマージされた」に固定する。**

- Issueを `gh issue close` で手動closeしない。PR本文に `Closes #N` を書き、マージによる自動closeに任せる
- 理由: fan-in(統合)タスクは依存Issueのcloseをトリガーに着手する。closeがマージより先に来ると、
  統合タスクが依存コードを含まないmainから分岐してしまう

## 4. 並列実行のルール

- 独立したタスク(依存関係のないIssue)は `scripts/spawn-worktree.sh` で別worktreeに分離してから着手する
- `spawn-worktree.sh` は着手時に `in-progress` ラベル+assigneeを付けてIssueをclaimする。
  既に `in-progress` のIssueには着手しない(スクリプトが拒否する)
- 同じファイル・同じモジュールを複数エージェントが同時に触らないよう、担当範囲(glob)をIssue本文に明記する
- 統合(fan-in)タスクは、依存Issueが全てcloseされるまで `blocked` ラベルのまま着手しない
  (`scripts/check-blocked.sh` が自動でラベルを付け替える)

## 5. 完了の定義(Definition of Done)

以下を満たすまで「完了」としない:

1. 該当するテストが全て通る
2. `.claude/skills/code-review/SKILL.md` の観点でverifierのレビューを通過している
3. 変更内容がGitHub Issue(またはPR)にコメントとして要約されている
4. 学びがあれば該当Skillの `learnings/` に1エントリ1ファイルで追記されている
5. PRがmainにマージされ、Issueが自動closeされている

## 6. エスカレーション条件

以下の場合は自動処理を止め、Issueに `needs-human` ラベルを付けて人間に確認する:

- 同一Issueに対する自動修正の試行(テスト・ビルド・lint等の失敗対応を合算)が5回を超えた場合
- 既存の公開APIやDBスキーマを変更する場合
- 依存パッケージの追加・更新が必要な場合
- セキュリティ・認証・支払いに関わるコードを触る場合
- **`.github/workflows/`、`AGENTS.md`、`.claude/skills/` 配下のSKILL.md本体を変更する場合**
  (エージェントによる自己権限拡大にあたるため、人間の承認なしに変更しない)
- force-push、ブランチ/タグの削除、コミット履歴の書き換えを行う場合
- データ削除を伴うマイグレーションや、既存データの一括更新を行う場合
- 外部APIの利用など、継続的な課金・コストが発生する操作を行う場合
- `.env` やSecretsなど秘密情報に触れる必要がある場合
- 依存Issueが再オープンされたが、自分のタスクが既に着手済みの場合(継続/破棄の判断は人間が行う)

## 7. ナレッジ管理

- 「今回だけの一時的なメモ」→ 該当Skillの `learnings/` に1エントリ1ファイルで追加
  (ファイル名: `YYYY-MM-DD-<slug>.md`。単一ファイル追記はworktree間でmerge conflictを起こすため禁止)
- 「プロジェクト全体に関わる決定事項」→ `knowledge/decisions/`
- 「調査した結果・比較検討」→ `knowledge/research/`
- **ai-workspaceテンプレート(`docs/ai/`)導入済みのプロジェクトでは `docs/ai/` を知識層の正とする。**
  decisions・researchは `knowledge/` ではなく `docs/ai/` 配下に `docs/ai/RULES.md` の書式で記録する。
  各Skillの `learnings/`(1エントリ1ファイル)は並列worktreeでのconflict回避のためそのまま使う

learningsは誤った学びが全エージェントに伝播しないよう、mainへの反映は必ずPR経由とし、
scribe(または人間)がレビューする。月次で棚卸し(重複統合・陳腐化した記述のアーカイブ)を行う
(手順: `scripts/prune-learnings.md`)。
