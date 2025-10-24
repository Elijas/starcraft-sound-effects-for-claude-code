#!/bin/bash

# Quick debug checker - shows latest debug logs and diagnostics

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
DEBUG_LOG="${LOG_DIR}/debug.log"

if [ ! -f "$DEBUG_LOG" ]; then
    echo "No debug log found yet. Run Claude Code first, then check again."
    exit 1
fi

echo "========== DEBUG LOG =========="
cat "$DEBUG_LOG"
echo ""
echo "========== LOG FILES =========="
ls -lh "$LOG_DIR"
