#!/usr/bin/env bash
# どこ: Claude Code の PreCompact フック(manual / auto)。
# 何: 実在する記録の場所と、要約に残す作業状態を短く標準出力へ渡す。
# なぜ: 要約後も記録から作業を再開できるようにする。失敗しても要約は止めない。

command -v jq >/dev/null 2>&1 || exit 0
input=$(jq -ec -s '
  select(length == 1) | .[0] |
  select(type == "object") |
  select(.trigger == "manual" or .trigger == "auto") |
  select(.cwd | type == "string") |
  select(.cwd | startswith("/")) |
  select(.cwd | test("[\\x00-\\x1f\\x7f]") | not)
' 2>/dev/null) || exit 0
record_cwd=$(printf '%s' "$input" | jq -r '.cwd' 2>/dev/null) || exit 0
trigger=$(printf '%s' "$input" | jq -r '.trigger' 2>/dev/null) || exit 0
record_cwd=$(cd -- "$record_cwd" 2>/dev/null && pwd -P) || exit 0
roots=("$record_cwd")
git_root=$(git -C "$record_cwd" rev-parse --show-toplevel 2>/dev/null) || git_root=''
if [ -n "$git_root" ] && [ "$git_root" != "$record_cwd" ]; then
  roots+=("$git_root")
fi

records=()
shopt -s nullglob
for root in "${roots[@]}"; do
  for name in docs/STATUS.md STATUS.md docs/decisions docs/knowledge; do
    path="$root/$name"
    if [[ "$name" == *.md ]]; then
      [ -f "$path" ] && records+=("$path")
    else
      [ -d "$path" ] && records+=("$path/")
    fi
  done
  # reports 直下の日付名だけを比較する。再帰探索や本文の読み込みはしない。
  latest=''
  latest_date=''
  for dir in "$root"/reports/*; do
    [ -d "$dir" ] || continue
    date_name=${dir##*/}
    [[ "$date_name" =~ ^(work-)?[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue
    date_name=${date_name#work-}
    # 同日なら通常の日付名を優先する(glob で work- より先に並ぶ)。
    if [[ -z "$latest_date" || "$date_name" > "$latest_date" ]]; then
      latest=$dir
      latest_date=$date_name
    fi
  done
  if [ -n "$latest" ] && [ -f "$latest/PLAN.md" ]; then
    records+=("$latest/PLAN.md")
  fi
done

# パスを JSON の文字列として引用し、改行等を要約の指示として混ぜない。
paths=$(jq -cn --args '$ARGS.positional | unique' "${records[@]}" 2>/dev/null) || exit 0
# 公式の上限(10,000文字)より小さくする。異常に長ければ出力せず継続。
[ "${#paths}" -le 8000 ] || exit 0
printf '要約(%s)には未完の作業・決まったこと・次の一手・誰に何を頼んでいるかを残してください。\n' "$trigger"
printf '存在を確認した記録の場所(JSON配列、空なら該当なし): %s\n' "$paths"
printf 'この一覧の場所と、会話で確かめた作業状態を要約に残し、推測で補わないでください。\n'
exit 0
