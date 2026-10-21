#!/usr/bin/env bash
# agmsg を Pi で使えるようにする(dotfiles の install.sh から、agmsg のインストール後に呼ぶ)。
# agmsg は Pi を種類として持たないため、外部プラグイン types/pi を足す。
#   1. types/pi を agmsg の plugins/types/pi にリンクし、信頼済みにする(プラグインは信頼するまで無視される)
#   2. Pi 用の SKILL.md を ~/.pi/agent/skills/agmsg に作る。~/.agents/skills/agmsg/SKILL.md は
#      Codex 用に書き出された物で、Pi が読むと codex として名乗ってしまう。合成元の SKILL.md は
#      インストール先に残らないため、同じ版のソースを一時的に取得して agmsg 自身の描画処理で合成する。
# 受信(monitor)は Pi の拡張 pi/extensions/agmsg.ts が受け持つ。
set -euo pipefail

AGMSG_DIR="$HOME/.agents/skills/agmsg"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [ ! -x "$AGMSG_DIR/scripts/plugin.sh" ]; then
  echo "agmsg が未インストールのため Pi 対応をスキップ" >&2
  exit 0
fi

mkdir -p "$AGMSG_DIR/plugins/types"
ln -sfn "$HERE/types/pi" "$AGMSG_DIR/plugins/types/pi"
"$AGMSG_DIR/scripts/plugin.sh" trust types/pi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# agmsg の setup.sh は main を入れるため、VERSION のタグが無ければ main で合成する
# VERSION はタグ(例: v1.5.3)のこともコミットハッシュ(例: 93ba547)のこともある。
# ハッシュはブランチ名として clone できないので、タグの形のときだけ取りに行く。
# タグは v 付きなので、二重にならないよう先頭の v を外してから付ける
ver="$(cat "$AGMSG_DIR/VERSION" 2>/dev/null || true)"
if [[ "$ver" =~ ^v?[0-9]+\.[0-9]+ ]]; then
  ref="v${ver#v}"
  if ! git -c advice.detachedHead=false clone -q --depth 1 -b "$ref" https://github.com/fujibee/agmsg "$tmp/agmsg"; then
    echo "agmsg の $ref が取得できないため main で合成する" >&2
    git clone -q --depth 1 https://github.com/fujibee/agmsg "$tmp/agmsg"
  fi
else
  git clone -q --depth 1 https://github.com/fujibee/agmsg "$tmp/agmsg"
fi
# 一時ソースでは組み込みの種類として置けば信頼の手続きが要らない。
# 本家に pi が加わっていても、cp -R が中へ入れ子にコピーしないよう先に消す
rm -rf "$tmp/agmsg/scripts/drivers/types/pi"
cp -R "$HERE/types/pi" "$tmp/agmsg/scripts/drivers/types/pi"

mkdir -p "$HOME/.pi/agent/skills/agmsg"
SCRIPT_DIR="$tmp/agmsg" bash -c '
  . "$SCRIPT_DIR/scripts/lib/type-registry.sh"
  . "$SCRIPT_DIR/scripts/lib/skill-render.sh"
  agmsg_render_skill pi agmsg "$1"
' _ "$HOME/.pi/agent/skills/agmsg/SKILL.md"
echo "  + installed agmsg skill for Pi to ~/.pi/agent/skills/agmsg/"
