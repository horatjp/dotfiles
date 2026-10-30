#!/bin/sh
# Claude Code の statusLine から herdr-agent-usage プラグインの statusline を呼ぶ。
# statusLine の入力(rate_limits)をプラグインに渡すと、herdr のサイドバーに Claude の利用上限の残りが出る。
# プラグインの置き場所は更新のたびに変わる(github-installations/usagebar-<hash>/<番号>/checkout)ため、
# 固定パスや更新日時で探さず、herdr が有効にしているものを毎回 herdr に聞く(約 10ms)。
# herdr・jq・プラグインのどれかが無いマシンでは、入力を読み捨てて何も出さずに終わる。
root=$(herdr plugin list --json 2>/dev/null |
  jq -r '.result.plugins[] | select(.plugin_id == "usagebar" and .enabled) | .plugin_root' 2>/dev/null)
[ -n "$root" ] && [ -f "$root/bin/run-statusline.sh" ] || { cat >/dev/null; exit 0; }
exec bash "$root/bin/run-statusline.sh"
