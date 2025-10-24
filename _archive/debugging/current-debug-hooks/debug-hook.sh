#!/bin/bash

# Debug Hook - Wrapper around production router
# Logs debug info to gitignored directory only
# Calls production router to play sounds

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
DEBUG_LOG="${LOG_DIR}/debug.log"
DEBUG_INPUT="${LOG_DIR}/hook-input.json"
DEBUG_TRANSCRIPT="${LOG_DIR}/transcript-capture.json"

# Create logs directory (gitignored)
mkdir -p "$LOG_DIR"

# Capture stdin
HOOK_INPUT=$(cat)

# Log only to gitignored directory
{
    echo "=========================================="
    echo "Hook triggered at: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    echo ""
    echo "HOOK INPUT:"
    echo "$HOOK_INPUT" | jq . 2>/dev/null || echo "$HOOK_INPUT"
    echo ""
} > "$DEBUG_LOG"

# Save input JSON
echo "$HOOK_INPUT" > "$DEBUG_INPUT"

# Extract transcript path
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcriptPath // .transcript_path // empty' 2>/dev/null || echo "")

{
    echo "Transcript path: $TRANSCRIPT_PATH"
    if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
        echo "Transcript exists: YES"
        cp "$TRANSCRIPT_PATH" "$DEBUG_TRANSCRIPT" 2>/dev/null || true

        echo ""
        echo "Last assistant message in transcript:"
        jq -r '
            [.[] | select(.role == "assistant" or (.message.role == "assistant"))] |
            last |
            .content[-1].text // .message.content[-1].text // "NO TEXT FOUND"
        ' "$TRANSCRIPT_PATH" 2>/dev/null || echo "FAILED TO PARSE"
    else
        echo "Transcript exists: NO"
    fi
    echo ""
} >> "$DEBUG_LOG"

# Call production router and capture output
{
    echo "Running production router..."
    echo "Command: /Users/user/Development/starcraft-sound-effects-for-claude-code/starcraft-sound-router-v3.sh"
    echo ""
} >> "$DEBUG_LOG"

ROUTER_OUTPUT=$(echo "$HOOK_INPUT" | /Users/user/Development/starcraft-sound-effects-for-claude-code/starcraft-sound-router-v3.sh 2>&1 || true)
ROUTER_EXIT=$?

{
    echo "Router stdout:"
    echo "$ROUTER_OUTPUT"
    echo ""
    echo "Router exit code: $ROUTER_EXIT"
    echo ""
    echo "========== DIAGNOSTIC INFO =========="

    SOUND_JSON="/Users/user/Development/starcraft-sound-effects-for-claude-code/starcraft-sounds.json"
    if [ -f "$SOUND_JSON" ]; then
        SOUND_DIR=$(jq -r '.base_path // empty' "$SOUND_JSON" 2>/dev/null || echo "")
        echo "Sound directory: $SOUND_DIR"
        if [ -d "$SOUND_DIR" ]; then
            echo "Sound dir exists: YES"
            echo "Sound files count: $(find "$SOUND_DIR" -name "*.wav" 2>/dev/null | wc -l)"
        else
            echo "Sound dir exists: NO"
        fi
    fi

    echo ""
    echo "Router log file:"
    ROUTER_LOG="/Users/user/Development/starcraft-sound-effects-for-claude-code/router.log"
    if [ -f "$ROUTER_LOG" ]; then
        tail -20 "$ROUTER_LOG"
    else
        echo "Router log file not found"
    fi
    echo ""
} >> "$DEBUG_LOG"

exit 0
