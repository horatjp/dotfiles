#!/bin/bash
# setup-labels.sh
#
# 目的: このテンプレートの運用に必要なラベルを一括作成する。
#       リポジトリ作成直後に1回実行する。既存ラベルはスキップされる(冪等)。
#
# 使い方:
#   ./scripts/setup-labels.sh

set -euo pipefail

create_label() {
  local name="$1" color="$2" desc="$3"
  if gh label create "$name" --color "$color" --description "$desc" 2>/dev/null; then
    echo "作成: $name"
  else
    echo "スキップ(既存): $name"
  fi
}

create_label "todo"        "0E8A16" "着手可能なタスク"
create_label "blocked"     "D93F0B" "依存Issueの完了待ち(check-blocked.shが自動でtodoに付け替える)"
create_label "in-progress" "FBCA04" "エージェントが着手中(spawn-worktree.shが自動で付与)"
create_label "needs-human" "B60205" "エスカレーション: 人間の判断が必要"

# skill/<name> ラベル: .claude/skills/ 配下から自動検出して作成する
# (AGENTS.md 2節「Issueには必ず skill/<skill-name> ラベルを付ける」の前提を満たすため)
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
for skill_dir in "$REPO_DIR"/.claude/skills/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"
  create_label "skill/$skill_name" "1D76DB" "参照Skill: .claude/skills/$skill_name"
done

echo "done."
