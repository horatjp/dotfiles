#!/bin/sh
# Claude Code の statusLine 用。モデル・作業フォルダ・ブランチ・文脈/利用枠の残りを1行で出す。
# モデルはクリーム、フォルダは青、ブランチ・区切りは灰色。各部品に Nerd Font のアイコンを付ける。
# モデル・フォルダ・ブランチと ctx・5h・7d の各まとまり内は空白2つで結ぶ。
# 両方のまとまりがあるときだけ、灰色の │ を前後に空白1つずつ付けて挟む。
# ctx・5h・7d はラベル・電池・数字を残り50超=緑、20〜50=黄、20未満=赤の1色にする。
# 戻るまでの目安は7dだけに同じ色で付け、5hには付けない。
# 同じ入力を herdr-agent-usage にも渡し、herdr のサイドバーの利用枠表示を保つ。
# プラグインの文字出力は使わず、失敗しても自前の表示を続ける。情報がない部品だけ省き、全部空なら改行も出さない。
# プラグインの置き場所はコミットごとに変わるため、herdr が有効にしているものを毎回聞く。
# /bin/sh (macOS / dash) 用。jq が無ければ入力を読み捨て、何も出さず正常終了する。
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
root=$(herdr plugin list --json 2>/dev/null |
  jq -r '.result.plugins[] | select(.plugin_id == "usagebar" and .enabled) | .plugin_root' 2>/dev/null)
if [ -n "$root" ] && [ -f "$root/bin/run-statusline.sh" ]; then
  printf '%s' "$input" | bash "$root/bin/run-statusline.sh" >/dev/null 2>&1
fi
# git の作業ツリー走査はせず、ブランチ名だけ読む。非 git / detached HEAD は省く。
dir=$(printf '%s' "$input" | jq -r 'objects | .workspace | objects | .current_dir | strings' 2>/dev/null)
branch=''
if [ -n "$dir" ]; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" branch --show-current 2>/dev/null)
fi
now=$(date +%s)
printf '%s' "$input" | jq -r --arg branch "$branch" --argjson now "$now" '
  def cream: "167;154;124";
  def muted: "107;111;120";
  def paint($c): "\u001b[38;2;" + $c + "m" + . + "\u001b[0m";
  # 名前に改行などがあっても1行表示を保つ。
  def name: if type == "string" then gsub("[\u0001-\u001f\u007f-\u009f]"; " ") else "" end;
  # 従来どおり、残りを計算して四捨五入し、0〜100に収める。
  def remaining:
    if type == "number" then
      100 - . | if . < 0 then 0 elif . > 100 then 100 else (. + 0.5 | floor) end
    else empty end;
  # 最も近い10%段階へ丸める。5%境界は上の段 (95%なら100の電池)。
  def battery:
    ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][(. / 10 + 0.5 | floor)];
  def remaining_color:
    if . > 50 then "107;131;96" elif . >= 20 then "168;157;118" else "200;96;90" end;
  def amount: battery + " " + tostring + "%";
  # Unix秒は西暦9999年末まで。異常値は目安だけ省き、過去は ~0m。
  # 分で切り上げてから単位を選び、~60m / ~24h は上の単位へ繰り上げる。
  def estimate:
    if type == "number" and . >= 0 and . <= 253402300799 then
      ([0, . - $now] | max) / 60 | ceil |
      if . > 1380 then "~" + (. / 1440 | ceil | tostring) + "d"
      elif . >= 60 then "~" + (. / 60 | ceil | tostring) + "h"
      else "~" + tostring + "m" end
    else empty end;
  def window($label):
    objects | . as $w | (.used_percentage | remaining) as $n |
    ($label + " " + ($n | amount) +
      (if $label == "7d" then [$w.resets_at | estimate | " (" + . + ")"] | join("") else "" end)) |
    paint($n | remaining_color);
  # オブジェクト型を部品ごとに絞り、壊れた部品をほかへ波及させない。
  objects | . as $data |
  [
    ([
      ($data.model | objects | .display_name | name | select(length > 0) |
        "󰚩 " + . + ([$data.effort | objects | .level | name | select(length > 0) | " " + .] | join("")) | paint(cream)),
      ($data.workspace | objects | .current_dir | name | select(length > 0) |
        sub("/+$"; "") | if . == "" then "/" else split("/") | last end |
        "󰉋 " + . | paint("110;150;190")),
      ($branch | name | select(length > 0) | "󰘬 " + . | paint(muted))
    ] | join("  ")),
    ([
      ($data.context_window | objects | .used_percentage | remaining | . as $n | ("ctx " + amount) | paint($n | remaining_color)),
      ($data.rate_limits | objects | .five_hour | window("5h")),
      ($data.rate_limits | objects | .seven_day | window("7d"))
    ] | join("  "))
  ] | map(select(length > 0)) | select(length > 0) | join(" " + ("│" | paint(muted)) + " ")
' 2>/dev/null
exit 0
