# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

個人用dotfiles。macOS / Windows / WSL / devcontainer の環境構築スクリプトと、各種ツール設定（zsh, tmux, nvim, git, wezterm など）、および AIエージェント設定（Claude Code, Codex, Pi）を管理する。ビルド・テスト・リンターは存在しない。

## コマンド

環境ごとのエントリポイント（いずれもシンボリックリンク作成とツールインストールを行う）:

```bash
bash install.sh              # WSL / macOS 共通のシェル環境セットアップ
bash setup.macos.sh          # macOS 初期セットアップ（install.sh の前に実行する。install.sh は呼ばない）
bash install.devcontainer.sh # devcontainer 用の軽量セットアップ
# setup.windows.ps1          # Windows (PowerShell)
```

シェルスクリプト変更時の検証は `bash -n <script>` で構文チェックする。`install.sh` は実行すると実際にホーム配下へリンクを張り替えるため、動作確認目的で安易に実行しない。

Windows側設定のバックアップ手順（Windows Terminal / VS Code / winget のエクスポート）は `NOTES.md` に記載。

## アーキテクチャ

### symlink 方式（最重要）

`install.sh` がリポジトリ内ファイルを `~/` や `~/.config/` へ**シンボリックリンク**する。つまりこのリポジトリのファイルを編集すると、稼働中の環境設定が即座に変わる。例:

- `claude/AGENTS.md` → `~/.claude/CLAUDE.md`（ユーザーのグローバル指示）
- `agents/skills` → `~/.claude/skills` と `~/.codex/skills`（共有スキルの実体）、`claude/agents` → `~/.claude/agents`
- `pi/extensions` → `~/.pi/agent/extensions`（Pi の拡張。確認ダイアログと保護パスは Pi 公式 examples からのコピー。`openrouter-credits.ts` は OpenRouter の残高を表示し、管理用のキーを `~/.env` の `OPENROUTER_MANAGEMENT_KEY` から環境変数経由で読む。`opencode-go-usage.ts` は OpenCode Go の5時間・週・月の使用率を表示する(公式の資料に無い入口 `/inference/go/v1/usage` を `OPENCODE_GO_API_KEY` で読む。入口が変われば取得失敗と出るだけで Pi は止まらない)。`herdr-agent-state.ts` は `herdr integration install pi` が書く herdr への状態報告で、手で編集しない。`claude/hooks/herdr-agent-state.sh` も同様）
- `pi/models.json` → `~/.pi/agent/models.json`（Pi は OpenCode Go を優先し、そこに無いモデルだけ OpenRouter で使う。Pi に「Go に無ければ OpenRouter」の切り替えは無いので、モデルを選ぶときに `opencode-go/` か `openrouter/` かを決める。起動時の既定（Pi が書く settings.json の `defaultProvider`）やセッションの復元では Pi がモデルを選ぶことがあるので、課金先は画面で確かめる。OpenCode Go のキーは `~/.env` の `OPENCODE_GO_API_KEY` を読む（Pi の既定の `OPENCODE_API_KEY` は従量課金の OpenCode Zen とも共通のため使わない）。`~/.env` にキーがあるほかのプロバイダー（anthropic・openai・google・xai・kimi-coding）と Zen は、キーを未定義の `$PI_DISABLED_KEY` に向けて外す。`~/.env` に Pi が読む別のキーを足したら、ここにも足す（`pi --list-models` の provider 列が `opencode-go` と `openrouter` だけなら外れている）。`/login` などで `~/.pi/agent/auth.json` に保存したキーは models.json より優先され、この外し方が効かなくなるので保存しない。OpenRouter の振り分けモデルは文脈の上限を 128K に下げ、自動圧縮を早めにかける）
- `herdr-app/settings.json`・`herdr-app/layouts/mine.json` → `~/.config/herdr-app/` の同じ場所、`herdr/sounds` → `~/.config/herdr-app/sounds`（Herdr のデスクトップアプリ。試用中で、herdr-app の CLI・アプリ本体・設定フォルダのどれかがあるマシンだけ。通知音は TUI の herdr と同じ音を settings.json の `sounds` から相対パスで読む。settings.json と mine.json は既存の実ファイルを `.bak.<日時>.<pid>` に退避してからリンクする。sounds の実ファイル・実フォルダや、mine.json などの位置にあるフォルダは触らず警告して飛ばす。Herdr が書く状態のファイルや生成物は管理しない。Herdr は settings.json をリンク先へ書き込むので、アプリで設定を変えると dotfiles に差分が出る）
- `zsh/`, `nvim/`, `tmux/`, `git/`, `starship/` なども同様
- `~/.env` は git 管理外で、実体はマシンごとに用意する。Mac は 1Password Environments をマウントした名前付きパイプ（読むたびに 1Password が値を渡す）、WSL 等は `op://` 参照を書いた通常ファイル（`.zshrc` が `op inject` で展開してキャッシュ）。`.zshrc` は種類を見て読み方を切り替える。install.sh は無ければ警告するだけで、テンプレートは持たない

**例外（マージ方式）**: `claude/settings.base.json` は共有ベースで、install.sh が jq で `~/.claude/settings.json`（実ファイル、git 管理外）へマージする。スカラーはベース優先、配列は和集合、ローカルだけのキーは残る。herdr 連携フックのようなマシン固有の絶対パスはベースに書かず、ローカル側に任せる。ベースを編集したら install.sh の Claude セクションを再実行して反映する。
`codex/config.toml` は system 層 `/etc/codex/config.toml` へリンクされ、Codex が書き込むユーザー層 `~/.codex/config.toml`（実ファイル、git 管理外）とキー単位で深くマージされる。共有したい項目だけを書き、配列キーは両層に重ねない。

**例外（コピー方式）**: `claude/mcp.json` → `~/.claude.json` はリンクではなくコピーされる。編集しても再コピーするまで環境には反映されない。Pi の `~/.pi/agent/settings.json` は Pi 自身も書き換えるため dotfiles では管理せず、install.sh が `skills` に `~/.claude/skills`（共有スキルを読む）を冪等に追加する。

### ドットなし/ドット付きディレクトリの関係

- ソースは**ドットなし**ディレクトリ: `claude/`、`codex/`、`agents/`
- リポジトリ直下の `/.github/` と `/.claude/` は gitignore されたローカルコピー（先頭 `/` でアンカーしているので、`templates/` 配下に同名のディレクトリを置いても追跡される）

### AIエージェント設定の並行管理

- `claude/AGENTS.md` と `codex/AGENTS.md` は内容を統一して維持する（日本語）。一方だけ変更しない
- 共有スキルの実体は `agents/skills/` の1か所に置き、Claude Code と Codex はディレクトリごとのリンクで同じ中身を読む。Codex が置く `.system/` は git で無視する。外部ツールが使う `~/.agents/skills/` は dotfiles 管理外として残す
- skills CLI（`npx skills`）で導入する外部配布スキル（Cloudflare公式など）はgitで追跡せず `.gitignore` に列挙し、`install.sh` で再インストールする。`--all` は全エージェント（約50個の `~/.<agent>/`）へ配布する意味なので使わず、`-a claude-code -s '*' --copy` のように明示する。`skills remove -s '*'` はリンク先の `agents/skills` 内の追跡ファイルまで消すので使わない
- スキルはコピーして他マシンでも使う前提。マシン固有の絶対パスを書かず `<skill-dir>` 等のプレースホルダを使う

### templates/

新規プロジェクトの下地となるテンプレート（`company-ai-staff-template`）。このリポジトリの設定ではなく、他プロジェクトへ展開するための成果物。
旧 `ai-workspace-template`・`dev-agent-template` は後継の [project-template](https://github.com/horatjp/project-template) リポジトリに統合され削除済み（後者の並列実行は project-template の `templates/modules/multi-agent/` に移したが、現在は使わない。マルチエージェントは `multi-agent-kickoff` スキルを使う）。新規プロジェクトはそちらを使う。

## コミット規約

Gitmoji + Conventional Commits、日本語の subject（例: `✨ feat(skills): ○○スキルを追加`）。詳細な規約とGitmojiマッピングは `agents/skills/git-commit/`（`SKILL.md` と `gitmoji-reference.md`）を参照。関心ごとにアトミックにコミットする。
