#!/bin/bash
# check-blocked.sh
#
# 目的: "blocked" ラベル付きのオープンIssueについて、本文の "Depends on: #x, #y" 行を
#       読み取り、依存Issueがすべてcloseされていたら blocked → todo に付け替える。
#       (fan-inパターン: 複数の作業完了を待って統合タスクを着手可能にする)
#
# 使い方: ./scripts/check-blocked.sh
#   GitHub CLI(gh)での認証と、対象リポジトリ内での実行が前提。
#   定期実行したい場合は cron 等に登録する。
#   詳細な運用は governance/coordination.md のレベル2を参照。

set -euo pipefail

command -v gh >/dev/null 2>&1 || { echo "エラー: GitHub CLI (gh) が必要です" >&2; exit 1; }

for num in $(gh issue list --label blocked --state open --json number --jq '.[].number'); do
  body="$(gh issue view "$num" --json body --jq .body)"
  deps="$(printf '%s\n' "$body" | grep -i '^depends on:' | head -1 | grep -oE '#[0-9]+' | tr -d '#' || true)"
  if [ -z "$deps" ]; then
    echo "#$num: 'Depends on:' 行が見つからないためスキップ"
    continue
  fi
  all_closed=true
  for dep in $deps; do
    state="$(gh issue view "$dep" --json state --jq .state)"
    if [ "$state" != "CLOSED" ]; then
      all_closed=false
      echo "#$num: 依存 #$dep が未完了(state=$state)"
      break
    fi
  done
  if [ "$all_closed" = true ]; then
    gh issue edit "$num" --remove-label blocked --add-label todo
    echo "#$num: 依存がすべて完了 → todo に変更"
  fi
done
