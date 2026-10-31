#!/bin/sh
# Claude Code の statusLine から herdr-agent-usage プラグインの statusline を呼ぶ。
# statusLine の入力(rate_limits)をプラグインに渡すと、herdr のサイドバーに Claude の利用上限の残りが出る。
# プラグインの置き場所は固定したコミットごとに変わる(install.sh が ~/.local/share/herdr-agent-usage/<コミット> を link する)ため、
# 固定パスや更新日時で探さず、herdr が有効にしているものを毎回 herdr に聞く(約 10ms)。
# herdr・jq・プラグインのどれかが無いマシンでは、入力を読み捨てて何も出さずに終わる。
root=$(herdr plugin list --json 2>/dev/null |
  jq -r '.result.plugins[] | select(.plugin_id == "usagebar" and .enabled) | .plugin_root' 2>/dev/null)
[ -n "$root" ] && [ -f "$root/bin/run-statusline.sh" ] || { cat >/dev/null; exit 0; }
# プラグインの出力(例: 5h:92% 7d:58%)の「枠:数字%」ごとに、残りの量で色を付ける。
# 数字は残り(herdr/plugins/usagebar.toml の limit_percent = "remaining")。50 より多い=暗めの緑、20〜50=暗めの黄、20 未満=赤。
# 20 は通知のしきい値の最初の値に合わせた。「数字+英字:数字%」の形の部分だけに色を付け、それ以外の文字はそのまま出す。
# /bin/sh のパイプは最後のコマンドの終了コードを返すので、プラグインの出力を一度受けてから色を付け、プラグインの終了コードで終わる
out=$(bash "$root/bin/run-statusline.sh"); status=$?
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
