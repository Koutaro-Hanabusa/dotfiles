#!/usr/bin/env bash
# Stop hook: prompt Claude to evaluate nb-knowledge trigger before stopping.
# Reads hook JSON from stdin, emits `{decision: block, reason: ...}` every turn
# so Claude always reconsiders. stop_hook_active on the 2nd call lets stop
# proceed, capping it to one reminder per turn.
set -euo pipefail

input=$(cat)

if [ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

if [ -f "$HOME/.is_work_pc" ]; then
  notebook="work"
else
  notebook="home"
fi

reason="Before stopping: if this turn produced a non-trivial insight (bug root cause, non-obvious API/framework behavior, architectural tradeoff, design decision, corrected misconception), invoke the nb-knowledge skill NOW via the Skill tool (notebook: ${notebook}:knowledge/). Skip if the turn was a trivial lookup, restated fact, or boilerplate confirmation — just let the stop proceed."

jq -cn --arg r "$reason" '{decision: "block", reason: $r}'
