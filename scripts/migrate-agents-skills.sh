#!/usr/bin/env bash
# どこ: dotfiles/scripts/migrate-agents-skills.sh(各マシンで1回だけ手で実行する)
# 何: スキルの実体を agents/skills に統一した変更(2026-10-23)を、このマシンのホームへ反映する。
#   1. ~/.claude/skills と ~/.codex/skills を ~/dotfiles/agents/skills へのリンクにする
#   2. Pi の settings.json の skills に、共有先と agmsg の除外を足す
#   3. ~/.agents/skills に残っている、agents/skills と同じ名前の写しを退避する(Pi と Codex で二重に見えるため)
# なぜ: Claude Code はセッションの中から ~/.claude/skills を張り替えても、コマンドの終わりに
#   セッション開始時の状態へ戻す。そのため Claude Code をすべて終了してから、ターミナルで実行する。
# 何度実行しても同じ結果になる。消さずに退避するので、戻すときは退避先から mv で戻せる。
set -euo pipefail

SRC="$HOME/dotfiles/agents/skills"
STAMP="$(date +%Y%m%d%H%M%S)-$$"
PI_SETTINGS="$HOME/.pi/agent/settings.json"
AGENTS_DIR="$HOME/.agents/skills"

die() { echo "$*" >&2; exit 1; }

# --- 変更の前にすべて確かめる(途中で止まって半端な状態にならないように) ---
[ -d "$SRC" ] || die "見つからない: $SRC(先に git pull する)"
command -v jq >/dev/null 2>&1 || die "jq がありません。入れてから実行してください。"

# コマンドの先頭か、node などのインタープリターの次が claude/pi のプロセスを探す。
# Claude Code のプロセス名は版数(例: 2.1.308)になるため、コマンドの中身で見る。
# node で直接起動したとき(node [オプション] .../claude-code/cli.js)は、引数のどこかにある
# パッケージのパスで見分ける
ps_out="$(ps -axo pid=,args=)" || die "プロセスの一覧が取れません(ps が失敗した)"
find_procs() {
  printf '%s\n' "$ps_out" | awk -v want="$1" -v pkg="$2" '
    { a = $2; sub(".*/", "", a)
      if (a == want) { print; next }
      if (a != "node" && a != "bun") next
      for (i = 3; i <= NF; i++) { f = $i; sub(".*/", "", f)
        if (f == want || index($i, pkg "/") > 0) { print; next } } }'
}
# Claude Code が動いていると、張ったリンクが戻される。
# Chrome 連携の常駐(--chrome-native-host)はセッションではないので数えない
claude_procs="$(find_procs claude claude-code | grep -v -- '--chrome-native-host' || true)"
[ -z "$claude_procs" ] || die "Claude Code が動いています。すべて終了してから、もう一度実行してください。
$claude_procs"
# Pi が動いていると、Pi が settings.json に書いた変更を上書きするおそれがある
pi_procs="$(find_procs pi pi-coding-agent || true)"
[ -z "$pi_procs" ] || die "Pi が動いています。すべて終了してから、もう一度実行してください。
$pi_procs"

if [ -f "$PI_SETTINGS" ]; then
  jq -e '(.skills == null) or (.skills | type == "array")' "$PI_SETTINGS" >/dev/null 2>&1 ||
    die "Pi の settings.json が読めないか、skills が配列ではありません: $PI_SETTINGS"
fi

# 退避先と同じ名前のものが既にあれば止める(中へ入れ子に移すのを防ぐ)
backup_path() {
  local path="$1.bak.$STAMP"
  [ ! -e "$path" ] && [ ! -L "$path" ] || die "退避先が既にあります: $path"
  printf '%s\n' "$path"
}

# --- 1. リンク。リンク以外のもの(ディレクトリ・ファイル)があれば先に退避する ---
link_skills() {
  local dst="$1" bak
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    bak="$(backup_path "$dst")"
    mv "$dst" "$bak"
    echo "退避: $dst -> $bak"
  fi
  ln -sfn "$SRC" "$dst"
  echo "リンク: $dst -> $(readlink "$dst")"
}
link_skills "$HOME/.claude/skills"
link_skills "$HOME/.codex/skills"

# --- 2. Pi の settings(skills の2項目だけを冪等に足す) ---
if [ -f "$PI_SETTINGS" ]; then
  cp -p "$PI_SETTINGS" "$(backup_path "$PI_SETTINGS")"
  tmp="$(mktemp "$PI_SETTINGS.XXXXXX")"
  jq '.skills = ((.skills // [])
        | reduce ("~/.claude/skills", "-~/.agents/skills/agmsg") as $e (.; if index([$e]) then . else . + [$e] end))' \
    "$PI_SETTINGS" > "$tmp"
  mv "$tmp" "$PI_SETTINGS"
  echo "Pi の skills: $(jq -c .skills "$PI_SETTINGS")"
else
  echo "Pi の settings がないので飛ばす: $PI_SETTINGS"
fi

# --- 3. ~/.agents/skills の重複を退避する ---
# agents/skills に同じ名前があるものだけが対象。agmsg は本体とデータベースがあるので、名前が重なっても動かさない
moved=0
backup_dir=""
# ~/.agents/skills 自体が共有先と同じ実体(リンクなど)なら、中身は写しではなく本体なので触らない
same_dir=false
if [ -d "$AGENTS_DIR" ] && [ "$(cd -P "$AGENTS_DIR" && pwd)" = "$(cd -P "$SRC" && pwd)" ]; then
  same_dir=true
  echo "~/.agents/skills は共有先と同じ実体なので、重複の退避は飛ばす"
fi
if [ -d "$AGENTS_DIR" ] && [ "$same_dir" = false ]; then
  for dir in "$AGENTS_DIR"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    [ "$name" = "agmsg" ] && continue
    [ -L "${dir%/}" ] && continue
    [ -e "$SRC/$name" ] || continue
    if [ -z "$backup_dir" ]; then
      backup_dir="$(backup_path "$HOME/.agents/skills-duplicates")"
      mkdir -p "$backup_dir"
    fi
    mv "${dir%/}" "$backup_dir/"
    echo "退避: $AGENTS_DIR/$name -> $backup_dir/"
    moved=$((moved + 1))
  done
fi
echo "~/.agents/skills の重複の退避: ${moved} 個"

echo
echo "完了。Claude Code・Codex・Pi を起動し直してください。"
