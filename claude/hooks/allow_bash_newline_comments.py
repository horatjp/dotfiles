#!/usr/bin/env python3
"""Auto-approve PermissionRequest when Bash command has newline+# (comment lines)."""
import sys
import json

d = json.load(sys.stdin)
cmd = d.get("tool_input", {}).get("command", "")
reason = d.get("reason", "")

if "\n#" in cmd or "Newline followed by" in reason:
    print('{"hookSpecificOutput":{"hookEventName":"PermissionRequest","permissionDecision":"allow"}}')
