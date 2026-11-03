#!/usr/bin/env bash
# Pi の actas と受信拡張で、同じ instance ID と lock を使う。
# agmsg の内部パスを組み立てず、既存の identity / lock API に委ねる。
set -euo pipefail

MODE="${1:?active or actas}"
PROJECT="${2:?project}"
SESSION_ID="${3:?Pi session id}"
SKILL_DIR="$HOME/.agents/skills/agmsg"
SCRIPTS="$SKILL_DIR/scripts"
export AGMSG_DAEMON_NOTICE_SKIP=1
source "$SCRIPTS/lib/actas-lock.sh"
source "$SCRIPTS/lib/resolve-project.sh"
SESSION_ID="$(agmsg_normalize_instance_id "$SESSION_ID" pi)"
PROJECT="$(agmsg_resolve_project "$PROJECT" pi)"
PAIRS="$(bash "$SCRIPTS/identities.sh" "$PROJECT" pi)"

case "$MODE" in
  actas)
    NAME="${4:?role name}"
    # 失敗時は前の役を維持する。成功したときだけ、このセッションの旧役を解放。
    bash "$SCRIPTS/actas-claim.sh" "$PROJECT" pi "$NAME" "$SESSION_ID"
    while IFS=$'\t' read -r team agent; do
      [ -n "$team" ] && [ "$agent" != "$NAME" ] || continue
      actas_lock_release "$team" "$agent" "$SESSION_ID"
    done <<< "$PAIRS"
    ;;
  active)
    # 拡張用の行プロトコル。登録数と所有数を別々に返し、複数所有も照会成功として扱う。
    active=""
    first_name=""
    registered_multiple=false
    multiple=false
    while IFS=$'\t' read -r team agent; do
      [ -n "$team" ] || continue
      if [ -n "$first_name" ] && [ "$first_name" != "$agent" ]; then registered_multiple=true; fi
      first_name="$agent"
      state="$(actas_lock_state "$team" "$agent" "$SESSION_ID")"
      case "$state" in unknown:*) echo "agmsg: $state" >&2; exit 1 ;; esac
      [ "$state" = mine ] || continue
      # 同名で複数チームに参加するのは可。異なる役を複数所有なら決めつけない。
      if [ -n "$active" ] && [ "$active" != "$agent" ]; then
        multiple=true
      fi
      active="$agent"
    done <<< "$PAIRS"
    printf 'name=%s\nowned_multiple=%s\n' "$active" "$multiple"
    printf 'registered_multiple=%s\n' "$registered_multiple"
    ;;
  *) echo 'usage: session.sh active|actas <project> <session_id> [name]' >&2; exit 2 ;;
esac
