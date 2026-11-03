<!-- Pi overlay. スロットの外の行は描画されない。pi/agmsg/install.sh が agmsg の元の SKILL.md と合成して ~/.pi/agent/skills/agmsg/SKILL.md を作る。 -->
<!-- agmsg:slot delivery -->
<!-- agmsg:render-overlay __AGENT_TYPE__ -->
  5. **REQUIRED — Do NOT skip this step.** Choose `monitor` or `off` delivery (empty input means `monitor`), then run `~/.agents/skills/__SKILL_NAME__/scripts/delivery.sh set <mode> __AGENT_TYPE__ "$(pwd)"`.
     Monitor is handled by the Pi extension `~/.pi/agent/extensions/agmsg.ts`: when the current turn ends it starts `watch.sh` and feeds each new message into this session. Never launch `watch.sh` yourself.
<!-- /agmsg:slot delivery -->
<!-- agmsg:slot execute-extra -->
In monitor mode, incoming messages arrive in this session as `agmsg` custom messages (one per message: `<ts> | <team> | <from> → <to> | <body>`); they are already marked read. Act on them, and reply with `send.sh` when a reply is needed.
<!-- /agmsg:slot execute-extra -->
<!-- agmsg:slot mode -->
If argument is "mode", run `~/.agents/skills/__SKILL_NAME__/scripts/delivery.sh status __AGENT_TYPE__ "$(pwd)"`.
For `mode monitor|off`, run `~/.agents/skills/__SKILL_NAME__/scripts/delivery.sh set <mode> __AGENT_TYPE__ "$(pwd)"`; reject `turn` and `both` (Pi has no turn hook).
<!-- /agmsg:slot mode -->
<!-- agmsg:slot actas -->
If argument starts with "actas" followed by an agent name:
1. Run `~/.agents/skills/__SKILL_NAME__/scripts/identities.sh "$(pwd)" __AGENT_TYPE__`. If needed, join the requested name with `join.sh <team> <name> __AGENT_TYPE__ "$(pwd)"`.
2. Run `bash ~/.agents/skills/__SKILL_NAME__/plugins/types/pi/session.sh actas "$(pwd)" "$PI_SESSION_ID" <name>`. Do not substitute an invented session ID. If `PI_SESSION_ID` is missing, report it and stop.
3. Only after the command succeeds, use `<name>` as the active FROM. If the claim fails, keep the previous role and report the failure.
4. The extension detects the bash tool call containing `session.sh`, `actas-claim.sh`, or `reset.sh` and rechecks locks at `agent_end` of this turn, bypassing the usual 30-second interval. After successful actas, reception restarts for this name at that boundary. Until then, messages for other roles may arrive. Never launch `watch.sh` yourself.
<!-- /agmsg:slot actas -->
<!-- agmsg:slot drop -->
If argument starts with "drop" followed by an agent name:
This removes the name's registration itself via `reset.sh`, not just its active role.
1. Run `~/.agents/skills/__SKILL_NAME__/scripts/reset.sh "$(pwd)" __AGENT_TYPE__ <name> "$PI_SESSION_ID"`. If `PI_SESSION_ID` is missing, report it and stop.
2. Clear the active FROM when it matches `<name>`. The extension rechecks the remaining locks at the end of this turn.
<!-- /agmsg:slot drop -->
