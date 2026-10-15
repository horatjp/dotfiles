#!/usr/bin/env bash
# Pi delivery plug — delivery.sh から source される(resolve_hooks_file を使う)。
#
# Pi には Claude Code の Monitor のような常駐コマンドの仕組みも、ターンの終わりの hook もない。
# そこで Pi の拡張 ~/.pi/agent/extensions/agmsg.ts が受信を受け持つ。
# ここではプロジェクトに目印ファイル(hooks_file)を置く・消すだけにし、
# 拡張がセッション開始時とターンの終わりにそれを見て watch.sh を起動・停止する。
# off のときの watcher 停止は既定の agmsg_delivery_on_disable(この種類の watch.sh だけを止める)に任せる。

agmsg_delivery_apply() {
  local type="$1" project="$2" mode="$3"
  local marker
  marker="$(resolve_hooks_file "$type" "$project")" || return 1
  rm -f "$marker"
  case "$mode" in
    monitor)
      mkdir -p "$(dirname "$marker")"
      echo "agmsg-delivery-mode: monitor" > "$marker"
      ;;
    off) : ;;
  esac
}

agmsg_delivery_on_enable() {
  [ "$1" = "monitor" ] || return 0
  echo "Pi: the agmsg extension starts the inbox watcher when this turn ends. Do not launch watch.sh yourself."
}

agmsg_delivery_status() {
  local type="$1" project="$2" marker
  marker="$(resolve_hooks_file "$type" "$project")" || return 1
  if grep -q "agmsg-delivery-mode: monitor" "$marker" 2>/dev/null; then
    echo "mode: monitor"
  else
    echo "mode: off"
  fi
}
