#!/bin/bash
# chat-with-chat.sh — One command for any AI system
# Usage: ./chat-with-chat.sh <system> <prompt>
#        ./chat-with-chat.sh grok "What is X?"
#        ./chat-with-chat.sh claude "Explain Y"
#
# The agent contract: stdout carries ONLY the response text. Progress,
# health chatter and audit lines ride logs/audit.log. Errors are
# one-line verdicts on stderr with exit 1. Agents never read the .js —
# selectors live in chat-tools.conf.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
AUDIT_LOG="$LOG_DIR/audit.log"
TIMESTAMP=$(date +%s)

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$AUDIT_LOG"; }
fail() { echo "chat-with-chat: FAIL $*" >&2; log "FAIL $*"; exit 1; }

if [ $# -lt 2 ]; then
  echo "Usage: $0 <system> <prompt>" >&2
  echo "Systems: grok, claude" >&2
  exit 2
fi

SYSTEM=$(echo "$1" | tr '[:upper:]' '[:lower:]')
shift
PROMPT="$*"

PROMPT_FILE="$LOG_DIR/.prompt-$TIMESTAMP.txt"
printf '%s' "$PROMPT" > "$PROMPT_FILE"

log "CHAT START → $SYSTEM"

if ! ./chat-health-check.sh "$SYSTEM" >> "$AUDIT_LOG" 2>&1; then
  echo "chat-with-chat: WARN health check found issues ($SYSTEM) — continuing" >&2
fi

if ! ./chat-send.sh "$SYSTEM" "$PROMPT_FILE" >> "$AUDIT_LOG" 2>&1; then
  fail "send failed ($SYSTEM) — see logs/audit.log"
fi

RESPONSE_FILE="$LOG_DIR/${SYSTEM}-response-$TIMESTAMP.txt"
if ! ./chat-wait.sh "$SYSTEM" "$RESPONSE_FILE" >> "$AUDIT_LOG" 2>&1; then
  fail "no response from $SYSTEM within timeout — see logs/audit.log"
fi

log "CHAT COMPLETE → $RESPONSE_FILE"
rm -f "$PROMPT_FILE"

# The locked surface: response tokens only.
cat "$RESPONSE_FILE"
