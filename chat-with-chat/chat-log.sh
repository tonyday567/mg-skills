#!/bin/bash
# chat-log.sh — Dump full conversation from current tab
# Usage: ./chat-log.sh <system>
#        ./chat-log.sh grok
#        ./chat-log.sh claude

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/chat-tools.conf"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <system>"
  echo "Systems: grok, claude"
  exit 1
fi

SYSTEM=$(echo "$1" | tr '[:upper:]' '[:lower:]')
SYSTEM_UPPER=$(echo "$SYSTEM" | tr '[:lower:]' '[:upper:]')

URL_VAR="${SYSTEM_UPPER}_URL_PATTERN"
BUBBLE_VAR="${SYSTEM_UPPER}_BUBBLE_CLASS"

URL_PATTERN="${!URL_VAR}"
BUBBLE_CLASS="${!BUBBLE_VAR}"

if [ -z "$URL_PATTERN" ] || [ -z "$BUBBLE_CLASS" ]; then
  echo "❌ Unknown system: $SYSTEM"
  exit 1
fi

TIMESTAMP=$(date +%s)
OUTPUT_FILE="$SCRIPT_DIR/logs/${SYSTEM}-conversation-${TIMESTAMP}.txt"
mkdir -p "$(dirname "$OUTPUT_FILE")"

node "$SCRIPT_DIR/chat-log.js" "$SYSTEM" "$URL_PATTERN" "$BUBBLE_CLASS" "$OUTPUT_FILE"

echo "✅ Conversation saved to: $OUTPUT_FILE"
