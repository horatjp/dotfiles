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
