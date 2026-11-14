#!/usr/bin/env bash
# どこ: multi-agent-kickoff/scripts/wait-signal.sh
# 何: 報告ファイルの「最後の空でない行」が合図になるのを待ち、結果を1行で出す。
# なぜ: playbook §4 の待ち方(最後の空でない行だけを見る・ファイルでないパスや読み取り失敗は
#       「合図なし」と分ける・上限の時間で「合図なし」)を、毎回の長い1行コマンドでなく同じ判定で使うため。
# 位置づけ: 報告ファイルの最後の空でない行を合図にして待つ(playbook §4)。
# 使い方: wait-signal.sh <報告ファイルのパス> <impl|review> [待つ秒数=600] [相手]
# 終了コード: 0 合図あり / 1 合図なし(時間切れ) / 2 読み取り失敗・パスの誤り・引数の誤り / 3 相手の停止
# 相手(TUI は agent 名、herdr-app は端末): 役を問わず渡すのを基本にする。渡すと毎回、報告ファイルの合図を先に見てから
#   相手の状態を読む(合図が状態より先なので、合図があれば相手が止まっていても 0)。状態は
#   blocked は両方、error・finished は herdr-app だけ停止に数える(TUI の error・finished は今までどおり待つ):
#   blocked・error が2回続いたら 3、herdr-app の finished は1回で 3。状態の取得に失敗したら 2。
#   herdr-app は、待ち始めたあとに相手のターン(`hc get --json` の .turn)が進み、状態が idle・done なのに合図が無い
#   ときも止まりとして 3(出力「止まり: <相手>: 合図なしで<状態>」)。待ち始めの時点で idle・done でターンが進んで
#   いないときは待ち続ける(依頼の直後は入力待ちのことが多いため)。TUI などターンが読めないときは従来どおり。
#   環境変数 WAIT_BASE_TURN に、依頼を送る前の .turn を渡すとそれを基準にする(無ければ待ち始めの最初の値)。
#   止まり(3)を返す直前に報告を読み直し、合図なら 0、読み取り失敗なら 2(状態の取得の間に書かれた合図を優先)。
#   相手を省くと報告だけを待つ。herdr-app の実機の blocked は未確認。
set -u

f=${1:-}; kind=${2:-}; max=${3:-600}; peer=${4:-}
if [ "$#" -gt 4 ] || [ -z "$f" ] || [ -z "$kind" ]; then
  echo "引数の誤り: wait-signal.sh <報告ファイル> <impl|review> [秒数] [相手]"; exit 2
fi
case $kind in
  impl)   re='^実装完了$' ;;
  # 初回は P1=n P2=n P3=n、再確認は先頭に「再確認 」が付く(playbook §4 と同じ)
  review) re='^(再確認 )?P1=[0-9]+ P2=[0-9]+ P3=[0-9]+$' ;;
  *) echo "引数の誤り: 種類は impl か review: $kind"; exit 2 ;;
esac
case $max in ''|*[!0-9]*) echo "引数の誤り: 秒数は整数: $max"; exit 2 ;; esac
# 先頭ゼロ(08 など)を算術式が8進数と読まないよう 10進に直す。桁あふれを避けて7桁までに限る
[ "${#max}" -le 7 ] || { echo "引数の誤り: 秒数が大きすぎる: $max"; exit 2; }
max=$((10#$max))

interval=5
elapsed=0
stopped=0
# WAIT_BASE_TURN: 依頼を送る前に監督が控えた hc get の .turn(整数)。あれば基準にする(初回取得前に終わっても検出できる)
turn0=${WAIT_BASE_TURN:-}
case $turn0 in *[!0-9]*) echo "引数の誤り: WAIT_BASE_TURN は整数: $turn0"; exit 2 ;; esac
[ -z "$turn0" ] || turn0=$((10#$turn0))
# 相手を省けば従来どおり。状態の取得・JSON の解釈の失敗は合図なしと分ける。
# 結果は STATE(状態)と TURN(ターン。herdr-app で数として読めたときだけ。無ければ空)に入れる。
read_state() {
  local json field
  STATE=""; TURN=""
  if [ "${HERDR_ENV:-}" = 1 ]; then
    json=$(herdr agent get "$peer" 2>/dev/null) || return 1
    field='.result.agent.agent_status'
  elif [ -n "${HC_TERMINAL_ID:-}" ]; then
    json=$(hc get "$peer" --json 2>/dev/null) || return 1
    # 終わった端末は {"state":"finished","status":null,...} を返すので、finished は .state から読む
    field='(if .state == "finished" then "finished" else .status.state end)'
    TURN=$(printf '%s\n' "$json" | jq -ers 'if length == 1 then .[0].turn | select(type == "number") | floor | tostring else empty end' 2>/dev/null) || TURN=""
  else
    return 1
  fi
  STATE=$(printf '%s\n' "$json" | jq -ers "if length == 1 then .[0] | $field | select(type == \"string\" and length > 0) else empty end" 2>/dev/null) || return 1
}
# 報告ファイルを読み、合図なら「合図あり」を出して 0 で終わる。読み取り失敗・パスの誤りは 2。合図なしなら戻る。
check_signal() {
  if [ -e "$f" ]; then
    # あるのに通常ファイルでない(フォルダなど)ものは、待たずに止める
    [ -f "$f" ] || { echo "通常ファイルでない: $f"; exit 2; }
    # 1回の読み取りで本文を取る(失敗は終了2)。NUL だけ捨てる。
    # そのうえで、空行・空白だけの行を飛ばした最後の空でない行を求める。Windows の改行(CRLF)は、
    # 各行の行末の \r を1つだけ落として吸収する(行の途中の \r は残し、合図を作らない)。
    # 空ファイル・空白だけはまだ合図なし。求める処理の失敗も終了2(部分出力は判定に使わない)。
    body=$({ tr -d '\000' < "$f"; } 2>/dev/null) || { echo "読み取り失敗: $f"; exit 2; }
    last=$(printf '%s\n' "$body" | awk '{ t=$0; sub(/\r$/, "", t) } t !~ /^[ \t]*$/ { l=t } END { print l }') \
      || { echo "読み取り失敗: $f"; exit 2; }
    if printf '%s\n' "$last" | grep -Eq "$re"; then
      echo "合図あり: $f: $last"; exit 0
    fi
  fi
}
# 止まりを返す直前に報告を読み直す。状態の取得の間に合図が書かれていれば合図を優先する(0、読み取り失敗は 2)。
stop3() { check_signal; echo "$1"; exit 3; }
while :; do
  # 完了の合図を先に見てから、各回の相手の状態を確かめる。
  check_signal
  if [ -n "$peer" ]; then
    read_state || { echo "状態の読み取り失敗: $peer"; exit 2; }
    state=$STATE
    # 基準のターン: WAIT_BASE_TURN(依頼を送る前の値)があればそれ。無ければ待ち始めの最初に読めた値
    [ -z "$TURN" ] || [ -n "$turn0" ] || turn0=$TURN
    case "$state" in
      idle|done)
        # 合図が無いまま、待ち始めよりターンが進んで入力待ちに戻った相手は待っても来ないので 3。
        # 待ち始めから idle・done でターンが進んでいないものは、依頼の直後とみなして待つ
        if [ -n "$TURN" ] && [ -n "$turn0" ] && [ "$TURN" -gt "$turn0" ]; then
          stop3 "止まり: $peer: 合図なしで$state"
        fi
        stopped=0 ;;
      blocked) stopped=$((stopped + 1)) ;;
      finished)
        # herdr-app だけ。報告に合図が無いまま終わった相手は待っても来ないので、すぐ 3
        if [ "${HERDR_ENV:-}" != 1 ]; then stop3 "止まり: $peer: finished"; fi
        stopped=0 ;;
      error)
        if [ "${HERDR_ENV:-}" != 1 ]; then stopped=$((stopped + 1)); else stopped=0; fi ;;
      *) stopped=0 ;;
    esac
    [ "$stopped" -lt 2 ] || stop3 "止まり: $peer: $state"
  fi
  # ファイルがまだ無いのは待つ。上限で「合図なし」
  [ "$elapsed" -ge "$max" ] && { echo "合図なし: $f"; exit 1; }
  step=$interval; [ $((max - elapsed)) -lt "$step" ] && step=$((max - elapsed))
  sleep "$step"; elapsed=$((elapsed + step))
done
