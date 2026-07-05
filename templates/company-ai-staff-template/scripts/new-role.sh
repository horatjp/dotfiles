#!/bin/bash
# new-role.sh
#
# 目的: roles/_template/ROLE_TEMPLATE.md をコピーして新しいロールの雛形を作成する。
#
# 使い方:
#   ./scripts/new-role.sh <role_id> "<タイトル>"
#
# 例:
#   ./scripts/new-role.sh sales-advisor "営業戦略アドバイザー"

set -euo pipefail

ROLE_ID="${1:-}"
TITLE="${2:-}"

if [ -z "$ROLE_ID" ] || [ -z "$TITLE" ]; then
  echo "Usage: $0 <role_id> \"<タイトル>\""
  exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROLE_DIR="$REPO_DIR/roles/$ROLE_ID"

if [ -d "$ROLE_DIR" ]; then
  echo "エラー: roles/$ROLE_ID は既に存在します"
  exit 1
fi

TODAY="$(date +%Y-%m-%d)"

mkdir -p "$ROLE_DIR"
sed "s/{{role_id}}/$ROLE_ID/g; s/{{title}}/$TITLE/g; s/{{today}}/$TODAY/g" \
  "$REPO_DIR/roles/_template/ROLE_TEMPLATE.md" > "$ROLE_DIR/ROLE.md"
sed "s/{{role_id}}/$ROLE_ID/g" \
  "$REPO_DIR/roles/_template/learnings_template.md" > "$ROLE_DIR/learnings.md"

echo "作成しました: $ROLE_DIR/ROLE.md"
echo ""
echo "次の手順:"
echo "1. $ROLE_DIR/ROLE.md の frontmatter(type / allow_general_knowledge / knowledge_sources 等)と"
echo "   本文の <!-- --> コメント部分を埋める"
echo "   ※追加する前に: 既存ロールの調整で表現できないか governance/role-registry.md で確認する"
echo "2. knowledge_sources に必要なフォルダがなければ knowledge/ 配下に追加し、"
echo "   knowledge/README.md の表を更新する"
echo "3. ./scripts/generate-registry.sh を実行して台帳とアクセスマップを再生成する"
echo "4. type: advisory の場合、governance/escalation.md の基準を満たしているか確認する"
echo "5. 実行サーフェスに配置する(Projects は 1ロール=1Project + knowledge_sources のみ"
echo "   アップロード。governance/execution-guide.md 参照)"
