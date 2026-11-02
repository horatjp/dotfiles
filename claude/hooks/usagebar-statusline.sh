#!/bin/sh
# Claude Code の statusLine にモデル名と文脈の残りを出し、herdr-agent-usage プラグインの statusline を呼ぶ。
# statusLine の入力(model.display_name / context_window.used_percentage / rate_limits)からモデル名と文脈の残りを取り出し、
# 同じ入力をプラグインに渡すと、利用上限の残りが続き、herdr のサイドバーにも Claude の利用上限の残りが出る。
# モデル名と文脈は Codex と同じ色合いを、上限の色(暗めの緑・黄)と同じくらいの明るさに落として出し、ある部品の間だけ灰色の中黒で区切る。
# プラグインの置き場所は固定したコミットごとに変わる(install.sh が ~/.local/share/herdr-agent-usage/<コミット> を link する)ため、
# 固定パスや更新日時で探さず、herdr が有効にしているものを毎回 herdr に聞く(約 10ms)。
# モデル名・文脈の使用率・herdr・プラグインが無い場合は、その部品だけを省く。
# jq が無いマシンでは、入力を読み捨てて何も出さずに終わる。
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty' 2>/dev/null)
# 残りを計算してから四捨五入する(使用率16.5なら残り83.5を84にする)。数値以外は出さない。
context=$(printf '%s' "$input" | jq -r '
  .context_window.used_percentage | if type == "number" then
    100 - . | if . < 0 then 0 elif . > 100 then 100 else (. + 0.5 | floor) end
    | "Context \(.)% left"
  else empty end' 2>/dev/null)
root=$(herdr plugin list --json 2>/dev/null |
  jq -r '.result.plugins[] | select(.plugin_id == "usagebar" and .enabled) | .plugin_root' 2>/dev/null)
# プラグインの出力(例: 5h:92% 7d:58%)の「枠:数字%」ごとに、残りの量で色を付ける。
# 数字は残り(herdr/plugins/usagebar.toml の limit_percent = "remaining")。50 より多い=暗めの緑、20〜50=暗めの黄、20 未満=赤。
# 20 は通知のしきい値の最初の値に合わせた。「数字+英字:数字%」の形の部分だけに色を付け、それ以外の文字はそのまま出す。
# /bin/sh のパイプは最後のコマンドの終了コードを返すので、プラグインの出力を一度受けてから色を付け、プラグインの終了コードで終わる
out=''
status=0
if [ -n "$root" ] && [ -f "$root/bin/run-statusline.sh" ]; then
  out=$(printf '%s' "$input" | bash "$root/bin/run-statusline.sh"); status=$?
fi
# ある部品だけを「 · 」で区切る。モデル名は暗めのクリーム、文脈は暗めの橙(Codex の #f6e2b7・#f2b590 を約7割の明るさにした色)にし、最後の部品の後だけ改行する。
separator=''
divider=$(printf ' \033[38;2;107;111;120m·\033[0m ')
color='167;154;124'
for part in "$model" "$context"; do
  if [ -n "$part" ]; then
    printf '%s\033[38;2;%sm%s\033[0m' "$separator" "$color" "$part"
    separator=$divider
  fi
  # モデル名を省いた場合も、次の部品(文脈)の色へ進める。
  color='165;123;98'
done
if [ -n "$out" ]; then
  printf '%s' "$separator"
elif [ -n "$separator" ]; then
  printf '\n'
fi
[ -n "$out" ] && printf '%s\n' "$out" | awk '{
  out = ""; s = $0
  while (match(s, /[0-9]+[a-z]+:[0-9]+%/)) {
    tok = substr(s, RSTART, RLENGTH); n = tok; sub(/^[^:]*:/, "", n); sub(/%$/, "", n); n += 0
    if (n > 50) c = "107;131;96"; else if (n >= 20) c = "168;157;118"; else c = "200;96;90"
    out = out substr(s, 1, RSTART - 1) "\033[38;2;" c "m" tok "\033[0m"
    s = substr(s, RSTART + RLENGTH)
  }
  print out s
}'
exit "$status"
