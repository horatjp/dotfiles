# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

個人用dotfiles。macOS / Windows / WSL / devcontainer の環境構築スクリプトと、各種ツール設定（zsh, tmux, nvim, git, wezterm など）、および AIエージェント設定（Claude Code, Codex, GitHub Copilot）を管理する。ビルド・テスト・リンターは存在しない。

## コマンド

環境ごとのエントリポイント（いずれもシンボリックリンク作成とツールインストールを行う）:

```bash
bash install.sh              # WSL / macOS 共通のシェル環境セットアップ
bash setup.macos.sh          # macOS 初期セットアップ（install.sh を含む前段）
bash install.devcontainer.sh # devcontainer 用の軽量セットアップ
# setup.windows.ps1          # Windows (PowerShell)
```

シェルスクリプト変更時の検証は `bash -n <script>` で構文チェックする。`install.sh` は実行すると実際にホーム配下へリンクを張り替えるため、動作確認目的で安易に実行しない。

Windows側設定のバックアップ手順（Windows Terminal / VS Code / winget のエクスポート）は `NOTES.md` に記載。

## アーキテクチャ

### symlink 方式（最重要）

`install.sh` がリポジトリ内ファイルを `~/` や `~/.config/` へ**シンボリックリンク**する。つまりこのリポジトリのファイルを編集すると、稼働中の環境設定が即座に変わる。例:

- `claude/AGENTS.md` → `~/.claude/CLAUDE.md`（ユーザーのグローバル指示）
- `claude/settings.json` → `~/.claude/settings.json`
- `claude/skills` → `~/.claude/skills`、`claude/agents` → `~/.claude/agents`
- `zsh/`, `nvim/`, `tmux/`, `git/`, `starship/` なども同様

**例外（コピー方式）**: `claude/mcp.json` → `~/.claude.json`、`codex/config.toml` → `~/.codex/config.toml` はリンクではなくコピーされる。これらを編集しても再コピーするまで環境には反映されない。

### ドットなし/ドット付きディレクトリの関係

- ソースは**ドットなし**ディレクトリ: `github/`（→ `~/.github/` にリンク）、`claude/`、`codex/`
- リポジトリ直下の `/.github/` と `/.claude/` は gitignore されたローカルコピー（先頭 `/` でアンカーされており、`templates/` 配下のテンプレートが同梱する `.github/` `.claude/` は追跡対象）
- Copilot 向け設定を変更するときは `.github/` ではなく `github/` を編集する

### AIエージェント設定の並行管理

- `claude/AGENTS.md`、`codex/AGENTS.md`、`github/AGENTS.md` は内容を統一して維持する（日本語）。一方だけ変更しない
- 汎用スキルは `claude/skills/` と `codex/skills/` の両方に置く。スキルを追加・更新したら両方への反映を検討する
- skills CLI（`npx skills`）で導入する外部配布スキル（Cloudflare公式など）はgitで追跡せず `.gitignore` に列挙し、`install.sh` で再インストールする
- スキルはコピーして他マシンでも使う前提。マシン固有の絶対パスを書かず `<skill-dir>` 等のプレースホルダを使う

### templates/

新規プロジェクトの下地となるテンプレート（`company-ai-staff-template`）。このリポジトリの設定ではなく、他プロジェクトへ展開するための成果物。
旧 `ai-workspace-template`・`dev-agent-template` は後継の [project-template](https://github.com/horatjp/project-template) リポジトリに統合され削除済み（後者は `templates/modules/multi-agent/`）。新規プロジェクトはそちらを使う。

## コミット規約

Gitmoji + Conventional Commits、日本語の subject（例: `✨ feat(skills): ○○スキルを追加`）。詳細な規約とGitmojiマッピングは `github/copilot-commit-message-instructions.md` を参照。関心ごとにアトミックにコミットする。
