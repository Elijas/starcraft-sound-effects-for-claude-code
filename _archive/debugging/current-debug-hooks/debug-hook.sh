#!/bin/bash

# Comprehensive Debug Hook
# Captures all hook data and calls the production router with logging

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBUG_LOG="${SCRIPT_DIR}/debug.log"
DEBUG_INPUT="${SCRIPT_DIR}/hook-input.json"
DEBUG_TRANSCRIPT="${SCRIPT_DIR}/transcript-capture.json"
ROUTER_LOG="${SCRIPT_DIR}/router-execution.log"

# Initialize log
{
    echo "=========================================="
    echo "Hook triggered at: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
} >> "$DEBUG_LOG"

# Capture stdin
HOOK_INPUT=$(cat)
echo "$HOOK_INPUT" > "$DEBUG_INPUT"

{
    echo "HOOK INPUT RECEIVED:"
    echo "$HOOK_INPUT" | jq . 2>/dev/null || echo "$HOOK_INPUT"
    echo ""
} >> "$DEBUG_LOG"

# Extract transcript path
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcriptPath // .transcript_path // empty' 2>/dev/null || echo "")

{
    echo "Extracted transcript path: $TRANSCRIPT_PATH"
    echo "Transcript exists: $([ -f "$TRANSCRIPT_PATH" ] && echo "YES" || echo "NO")"
} >> "$DEBUG_LOG"

# Capture transcript if it exists
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    cp "$TRANSCRIPT_PATH" "$DEBUG_TRANSCRIPT" 2>/dev/null || true

    {
        echo "Transcript copied to: $DEBUG_TRANSCRIPT"
        echo "Last 10 lines of transcript:"
        tail -10 "$TRANSCRIPT_PATH"
        echo ""
    } >> "$DEBUG_LOG"
fi

# Call production router and capture output
{
    echo "Calling production router..."
    echo "Command: echo '\$HOOK_INPUT' | /Users/user/Development/starcraft-sound-effects-for-claude-code/starcraft-sound-router-v3.sh"
    echo ""
} >> "$DEBUG_LOG"

ROUTER_OUTPUT=$(echo "$HOOK_INPUT" | /Users/user/Development/starcraft-sound-effects-for-claude-code/starcraft-sound-router-v3.sh 2>&1 || true)

{
    echo "Router output:"
    echo "$ROUTER_OUTPUT"
    echo ""
    echo "Router exit code: $?"
    echo ""
} >> "$DEBUG_LOG"

# Check if sound files exist
{
    echo "========== SOUND FILE VERIFICATION =========="
    SOUND_JSON="/Users/user/Development/starcraft-sound-effects-for-claude-code/starcraft-sounds.json"
    if [ -f "$SOUND_JSON" ]; then
        SOUND_DIR=$(jq -r '.base_path // empty' "$SOUND_JSON" 2>/dev/null || echo "")
        echo "Sound directory from JSON: $SOUND_DIR"
        echo "Sound directory exists: $([ -d "$SOUND_DIR" ] && echo "YES" || echo "NO")"

        if [ -d "$SOUND_DIR" ]; then
            echo "Number of .wav files in sound directory: $(find "$SOUND_DIR" -name "*.wav" | wc -l)"
            echo "First 5 sound files:"
            find "$SOUND_DIR" -name "*.wav" | head -5
        fi
    fi
    echo ""
} >> "$DEBUG_LOG"

# Display log summary
echo ""
echo "========== DEBUG INFO CAPTURED =========="
echo "Debug log: $DEBUG_LOG"
echo "Hook input: $DEBUG_INPUT"
if [ -f "$DEBUG_TRANSCRIPT" ]; then
    echo "Transcript: $DEBUG_TRANSCRIPT"
fi
echo "=========================================="
echo ""
echo "Last 20 lines of debug log:"
tail -20 "$DEBUG_LOG"

exit 0
