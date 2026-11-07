#!/usr/bin/env bash
# どこ: multi-agent-kickoff/scripts/wait-signal.sh
# 何: 報告ファイルの「最後の1行」が合図になるのを待ち、結果を1行で出す。
# なぜ: playbook §5 の待ち方(最後の1行だけを見る・ファイルでないパスや読み取り失敗は
#       「合図なし」と分ける・上限の時間で「合図なし」)を、毎回の長い1行コマンドでなく同じ判定で使うため。
# 位置づけ: agmsgd が無いとき(monitor のとき・agmsg を使わないチーム)の予備(2026-11-07。主は agmsg の本文の1行目と agmsgd の知らせ)。
# 使い方: wait-signal.sh <報告ファイルのパス> <impl|review> [待つ秒数=600]
# 終了コード: 0 合図あり / 1 合図なし(時間切れ) / 2 読み取り失敗・パスの誤り・引数の誤り
set -u

f=${1:-}; kind=${2:-}; max=${3:-600}
if [ -z "$f" ] || [ -z "$kind" ]; then
  echo "引数の誤り: wait-signal.sh <報告ファイル> <impl|review> [秒数]"; exit 2
fi
case $kind in
  impl)   re='^実装完了$' ;;
  # 初回は P1=n P2=n P3=n、再確認は先頭に「再確認 」が付く(playbook §5 と同じ)
  review) re='^(再確認 )?P1=[0-9]+ P2=[0-9]+ P3=[0-9]+$' ;;
  *) echo "引数の誤り: 種類は impl か review: $kind"; exit 2 ;;
esac
case $max in ''|*[!0-9]*) echo "引数の誤り: 秒数は整数: $max"; exit 2 ;; esac
# 先頭ゼロ(08 など)を算術式が8進数と読まないよう 10進に直す。桁あふれを避けて7桁までに限る
[ "${#max}" -le 7 ] || { echo "引数の誤り: 秒数が大きすぎる: $max"; exit 2; }
max=$((10#$max))

interval=5
elapsed=0
while :; do
  if [ -e "$f" ]; then
    # あるのに通常ファイルでない(フォルダなど)ものは、待たずに止める
    [ -f "$f" ] || { echo "通常ファイルでない: $f"; exit 2; }
    last=$(tail -n 1 "$f" 2>/dev/null) || { echo "読み取り失敗: $f"; exit 2; }
    # Windows の改行(CRLF)で書かれた報告でも合図を拾えるよう、行末の \r を落とす
    last=${last%$'\r'}
    if printf '%s\n' "$last" | grep -Eq "$re"; then
      echo "合図あり: $f: $last"; exit 0
    fi
  fi
  # ファイルがまだ無いのは待つ。上限で「合図なし」
  [ "$elapsed" -ge "$max" ] && { echo "合図なし: $f"; exit 1; }
  step=$interval; [ $((max - elapsed)) -lt "$step" ] && step=$((max - elapsed))
  sleep "$step"; elapsed=$((elapsed + step))
done
