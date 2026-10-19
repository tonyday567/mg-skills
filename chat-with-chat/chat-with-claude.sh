#!/bin/bash
# chat-with-claude.sh — Directed session harness for Claude via chat-with-chat
# Usage: ./chat-with-claude.sh <prompt-file-or-string>
#        ./chat-with-claude.sh loom/agent-f.md       # feed a card as prompt
#        ./chat-with-claude.sh "What is a functor?"  # inline prompt
#
# Multi-turn: run repeatedly in same Claude tab; context accumulates.
# Lockdown contract: stdout is chat-with-chat's exchange, byte for byte.
# Session log: logs/claude-session-<date>.md (skill-local, gitignored).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_LOG="$SCRIPT_DIR/logs/claude-session-$(date +%Y-%m-%d).md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ $# -lt 1 ]; then
  echo "Usage: $0 <prompt-file-or-string>" >&2
  exit 1
fi

INPUT="$*"

# Resolve: file or inline string?
if [ -f "$INPUT" ]; then
  PROMPT=$(cat "$INPUT")
  SOURCE="$INPUT"
else
  PROMPT="$INPUT"
  SOURCE="inline"
fi

mkdir -p "$(dirname "$SESSION_LOG")"

# Send via chat-with-chat; stdout is the contract, capture for the log
RESPONSE=$("$SCRIPT_DIR/chat-with-chat.sh" claude "$PROMPT")

cat >> "$SESSION_LOG" <<EOF

---

## ⟝ $TIMESTAMP · $SOURCE

**prompt:**

$PROMPT

**response:**

$RESPONSE
EOF

printf '%s\n' "$RESPONSE"
