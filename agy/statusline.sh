#!/bin/sh
# Antigravity CLI の JSON から、モデル・作業場所・コンテキストと利用枠の残りを1行で表示する。
if ! command -v jq >/dev/null 2>&1; then
  command -p cat >/dev/null
  exit 0
fi
input=$(cat)

# 生のパスで現在のブランチだけを読む。末尾の改行をパスから落とさないよう印を付ける。
dir=$(printf '%s' "$input" | jq -js '
  select(length == 1) | .[] | objects | .workspace | objects | .current_dir | strings |
  select(length > 0 and (contains("\u0000") | not)) | . + "."
' 2>/dev/null)
branch=''
if [ -n "$dir" ]; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "${dir%.}" branch --show-current 2>/dev/null)
fi

printf '%s' "$input" | jq -rs --arg branch "$branch" '
  def muted: "107;111;120";
  def paint($c): "\u001b[38;2;" + $c + "m" + . + "\u001b[0m";
  def name: strings | gsub("[\u0000-\u001f\u007f-\u009f]"; " ") | select(length > 0);
  def model_name:
    . as $model | .display_name | name | . as $display |
    [ascii_downcase | splits("[^a-z0-9]+")] as $words |
    $display + ([$model.effort | name | . as $effort |
      ($effort | ascii_downcase) as $word |
      select(($words | index($word)) == null) | " " + $effort] | join(""));
  def number: numbers | select(isfinite);
  def percentage: if . < 0 then 0 elif . > 100 then 100 else (. + 0.5 | floor) end;
  def battery:
    ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][(. / 10 + 0.5 | floor)];
  def remaining_color:
    if . > 50 then "107;131;96" elif . >= 20 then "168;157;118" else "200;96;90" end;
  def amount: battery + " " + tostring + "%";
  def context_remaining:
    (.remaining_percentage | number) // (.used_percentage | number | 100 - .);
  def quota_name:
    . as $id |
    ((capture("^(?:(?<group>.*)[-_])?weekly$") | . + {label: "7d"}) //
      (capture("^(?:(?<group>.*)[-_])?(five[-_]hour|5[-_]?h|5[-_]hour)$") | . + {label: "5h"}) //
      {label: $id}) |
    if has("group") then .group = ((.group | name) // $id) else . end;
  # 公式例の UTC 時刻を使う。秒数があればそちらを優先し、1日超の枠だけ目安を出す。
  def reset_seconds:
    (.reset_in_seconds | number) //
    (.reset_time | strings | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601? | . - now);
  def estimate:
    reset_seconds | select(. > 86400) | . / 60 | ceil |
    " (~" + (. / 1440 | ceil | tostring) + "d)";
  def quota_item($label):
    . as $bucket |
    ((.remaining_fraction | number) // null) as $fraction |
    if $fraction != null then
      ($fraction * 100 | percentage) as $n |
      ($label + " " + ($n | amount) + ([$bucket | estimate] | join(""))) |
      paint($n | remaining_color)
    else
      .remaining_amount | number | $label + " " + tostring + ([$bucket | estimate] | join(""))
    end;
  def quota_items:
    objects | to_entries |
    map(select(.value | objects | select(.disabled != true) |
          [(.remaining_fraction, .remaining_amount) | number] | length > 0) |
        . + (.key | name | quota_name)) |
    # 表示できる枠で短縮名が重なったときだけ接頭辞を付け、最後に元の ID 順へ戻す。
    group_by(.label) | map(
      if length > 1 then
        group_by(.group) | map(
          (length > 1) as $same_group |
          map(if .group != null then
            .label = ((if $same_group then (.key | name) else .group end) + " " + .label)
          else . end)
        ) | flatten(1)
      else . end
    ) | flatten(1) | sort_by(.key) | .[] | .label as $label | .value | quota_item($label);

  select(length == 1) | .[] | objects | . as $data |
  [
    ([
      ($data.model | objects | model_name | "󰚩 " + . | paint("167;154;124")),
      ($data.workspace | objects | .current_dir | name |
        sub("/+$"; "") | if . == "" then "/" else split("/") | last end |
        "󰉋 " + . | paint("110;150;190")),
      ($branch | name | "󰘬 " + . | paint(muted))
    ] | join("  ")),
    ([
      ($data.context_window | objects | context_remaining | percentage | . as $n |
        ("ctx " + amount) | paint($n | remaining_color)),
      ($data.quota | quota_items)
    ] | join("  "))
  ] | map(select(length > 0)) | select(length > 0) | join(" " + ("│" | paint(muted)) + " ")
' 2>/dev/null
exit 0
