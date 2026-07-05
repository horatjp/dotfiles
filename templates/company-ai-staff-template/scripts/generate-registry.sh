#!/bin/bash
# generate-registry.sh
#
# 目的: roles/*/ROLE.md の frontmatter を唯一の正として、以下2ファイルの
#       <!-- BEGIN:GENERATED --> 〜 <!-- END:GENERATED --> 間の表を再生成する。
#         - governance/role-registry.md      (ロール台帳)
#         - governance/knowledge-access-map.md(ナレッジアクセスマップ)
#
# 使い方: ./scripts/generate-registry.sh
#   ロールの追加・変更・廃止のたびに実行する(表を手で編集しない)。

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$REPO_DIR/governance/role-registry.md"
ACCESS_MAP="$REPO_DIR/governance/knowledge-access-map.md"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

shopt -s nullglob
ROLE_FILES=("$REPO_DIR"/roles/*/ROLE.md)
if [ ${#ROLE_FILES[@]} -eq 0 ]; then
  echo "エラー: roles/*/ROLE.md が見つかりません" >&2
  exit 1
fi

awk -v regout="$TMP_DIR/registry.md" -v mapout="$TMP_DIR/map.md" '
function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
FNR == 1 { fm = 0; cur = "" }
/^---[[:space:]]*$/ { fm++; next }
fm != 1 { next }
/^[A-Za-z_]+:/ {
  key = $1; sub(/:$/, "", key)
  val = $0
  sub(/^[A-Za-z_]+:[[:space:]]*/, "", val)
  sub(/[[:space:]]*#.*$/, "", val)
  val = trim(val)
  gsub(/^"/, "", val); gsub(/"$/, "", val)
  cur = key
  v[FILENAME, key] = val
  if (key == "role_id" && val != "") { n++; files[n] = FILENAME }
  next
}
(cur == "knowledge_sources" || cur == "surfaces") && /^[[:space:]]*-[[:space:]]/ {
  item = $0
  sub(/^[[:space:]]*-[[:space:]]*/, "", item)
  item = trim(item)
  if (cur == "knowledge_sources") {
    folder = item
    sub(/^knowledge\//, "", folder)
    ks[FILENAME] = (ks[FILENAME] == "" ? "" : ks[FILENAME] ", ") folder
    if (!(folder in seenf)) { seenf[folder] = 1; nf++; folders[nf] = folder }
    acc[FILENAME, folder] = 1
  } else {
    sf[FILENAME] = (sf[FILENAME] == "" ? "" : sf[FILENAME] ", ") item
  }
  next
}
END {
  # フォルダ名を辞書順にソート(出力を決定的にする)
  for (i = 1; i <= nf; i++)
    for (j = i + 1; j <= nf; j++)
      if (folders[j] < folders[i]) { t = folders[i]; folders[i] = folders[j]; folders[j] = t }

  # --- ロール台帳 ---
  print "| role_id | title | 部門 | type | 一般知識補完 | 参照ナレッジ | エスカレーション必須 | 配置サーフェス | 状態 | 最終利用日 |" > regout
  print "|---|---|---|---|---|---|---|---|---|---|" > regout
  for (i = 1; i <= n; i++) {
    f = files[i]
    esc = (v[f, "escalation_required"] == "true") ? "✅" : "-"
    gk  = (v[f, "allow_general_knowledge"] == "true") ? "○" : "-"
    st  = (v[f, "status"] == "") ? "active" : v[f, "status"]
    lu  = (v[f, "last_used"] == "") ? "-" : v[f, "last_used"]
    srf = (sf[f] == "") ? "-" : sf[f]
    src = (ks[f] == "") ? "-" : ks[f]
    print "| " v[f, "role_id"] " | " v[f, "title"] " | " v[f, "department"] " | " v[f, "type"] " | " gk " | " src " | " esc " | " srf " | " st " | " lu " |" > regout
  }

  # --- ナレッジアクセスマップ ---
  header = "| ナレッジフォルダ \\ ロール |"
  sep = "|---|"
  for (i = 1; i <= n; i++) { header = header " " v[files[i], "role_id"] " |"; sep = sep "---|" }
  print header > mapout
  print sep > mapout
  for (k = 1; k <= nf; k++) {
    row = "| " folders[k] " |"
    for (i = 1; i <= n; i++) row = row " " (((files[i], folders[k]) in acc) ? "○" : "-") " |"
    print row > mapout
  }
}
' "${ROLE_FILES[@]}"

# マーカー間を生成結果で差し替える
splice() {
  local target="$1" gen="$2"
  awk -v genfile="$gen" '
    /<!-- BEGIN:GENERATED -->/ { print; while ((getline line < genfile) > 0) print line; close(genfile); skip = 1; next }
    /<!-- END:GENERATED -->/ { skip = 0 }
    skip != 1
  ' "$target" > "$target.tmp"
  mv "$target.tmp" "$target"
}

splice "$REGISTRY" "$TMP_DIR/registry.md"
splice "$ACCESS_MAP" "$TMP_DIR/map.md"

echo "再生成しました:"
echo "  - governance/role-registry.md"
echo "  - governance/knowledge-access-map.md"
