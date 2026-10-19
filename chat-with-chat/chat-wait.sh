#!/bin/bash
# chat-wait.sh — Generic wait + extract for any AI system via config
# Usage: ./chat-wait.sh <system> <output-file>
# Systems: grok, claude

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/chat-tools.conf"

if [ $# -lt 2 ]; then
  echo "Usage: $0 <system> <output-file>"
  echo "Systems: grok, claude"
  exit 1
fi

SYSTEM=$(echo "$1" | tr '[:upper:]' '[:lower:]')
OUTPUT_FILE="$2"
AUDIT_LOG="$HOME/mg/logs/browser-chat-audit.log"
CURSOR_FILE="$HOME/mg/logs/.chat-cursor"

# Load system-specific config
SYSTEM_UPPER=$(echo "$SYSTEM" | tr '[:lower:]' '[:upper:]')
BUBBLE_VAR="${SYSTEM_UPPER}_BUBBLE_CLASS"
TIMEOUT_VAR="${SYSTEM_UPPER}_TIMEOUT"
INTERVAL_VAR="${SYSTEM_UPPER}_INTERVAL"

BUBBLE_CLASS="${!BUBBLE_VAR}"
TIMEOUT="${!TIMEOUT_VAR}"
INTERVAL="${!INTERVAL_VAR}"

if [ -z "$BUBBLE_CLASS" ]; then
  echo "❌ Unknown system: $SYSTEM"
  exit 1
fi

# Read persistent cursor for this system
CURSOR_COUNT=0
if [ -f "$CURSOR_FILE" ]; then
  CURSOR_COUNT=$(grep "^${SYSTEM}:" "$CURSOR_FILE" 2>/dev/null | tail -1 | cut -d: -f2 | tr -d '[:space:]' || echo 0)
fi
CURSOR_COUNT=${CURSOR_COUNT:-0}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] WAIT START → $SYSTEM (cursor: $CURSOR_COUNT)" | tee -a "$AUDIT_LOG"

for ((i=0; i<TIMEOUT/INTERVAL; i++)); do
  # Check streaming status
  STREAMING=$("$SCRIPT_DIR/browser-eval.js" "
    (function() {
      var bubbles = document.querySelectorAll('$BUBBLE_CLASS');
      var last = bubbles[bubbles.length - 1];
      return last ? (last.innerText.trim().endsWith('...') || last.querySelector('.animate-pulse, .streaming') !== null) : false;
    })()
  " 2>/dev/null || echo "false")

  if [ "$STREAMING" = "false" ]; then
    echo "✅ Response complete — extracting full rich response"

    # Extract text from new responses only (skip cursor)
    RESPONSE_SELECTOR_VAR="${SYSTEM_UPPER}_RESPONSE_SELECTOR"
    RESPONSE_SELECTOR="${!RESPONSE_SELECTOR_VAR}"
    [ -z "$RESPONSE_SELECTOR" ] && RESPONSE_SELECTOR=".font-claude-response"
    
    "$SCRIPT_DIR/browser-eval.js" "
      (function() {
        var containers = Array.from(document.querySelectorAll('$RESPONSE_SELECTOR'));
        var cursor = ${CURSOR_COUNT};
        var newContainers = containers.slice(cursor);
        if (newContainers.length === 0) {
          // Cursor stale — fallback to last
          newContainers = containers.slice(-1);
        }
        return newContainers.map(function(c) { return c.innerText.trim(); }).join('\n\n');
      })()
    " > "$OUTPUT_FILE"

    cp "$OUTPUT_FILE" "$HOME/mg/logs/${SYSTEM}-response-$(date +%s).txt"

    # Update cursor with new total message count
    TOTAL_COUNT=$("$SCRIPT_DIR/browser-eval.js" "document.querySelectorAll('$RESPONSE_SELECTOR').length" 2>/dev/null || echo "0")
    TOTAL_COUNT=$(echo "$TOTAL_COUNT" | tr -d '[:space:]' || echo "0")
    TOTAL_COUNT=${TOTAL_COUNT:-0}

    mkdir -p "$(dirname "$CURSOR_FILE")"
    if [ -f "$CURSOR_FILE" ]; then
      grep -v "^${SYSTEM}:" "$CURSOR_FILE" > "$CURSOR_FILE.tmp" 2>/dev/null || true
      echo "${SYSTEM}:${TOTAL_COUNT}" >> "$CURSOR_FILE.tmp"
      mv "$CURSOR_FILE.tmp" "$CURSOR_FILE"
    else
      echo "${SYSTEM}:${TOTAL_COUNT}" > "$CURSOR_FILE"
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WAIT COMPLETE — full response saved (cursor → $TOTAL_COUNT)" | tee -a "$AUDIT_LOG"
    exit 0
  fi

  sleep "$INTERVAL"
done

echo "⚠️ Timeout waiting for $SYSTEM response"
exit 1
