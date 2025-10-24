#!/bin/bash

# Log Analysis Script - Run this after the hook fires to see what happened

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========== ANALYZING DEBUG LOGS =========="
echo ""

if [ ! -f "$SCRIPT_DIR/debug.log" ]; then
    echo "ERROR: No debug.log found. Hook hasn't been triggered yet."
    exit 1
fi

echo "=== DEBUG LOG ==="
cat "$SCRIPT_DIR/debug.log"
echo ""

if [ -f "$SCRIPT_DIR/hook-input.json" ]; then
    echo "=== HOOK INPUT (formatted) ==="
    jq . "$SCRIPT_DIR/hook-input.json" 2>/dev/null || cat "$SCRIPT_DIR/hook-input.json"
    echo ""
fi

if [ -f "$SCRIPT_DIR/transcript-capture.json" ]; then
    echo "=== TRANSCRIPT (last 5 messages) ==="
    jq '.[-5:]' "$SCRIPT_DIR/transcript-capture.json" 2>/dev/null || tail -20 "$SCRIPT_DIR/transcript-capture.json"
    echo ""
fi

echo "=== DIAGNOSTIC CHECKS ==="

# Check if production router exists
ROUTER="/Users/user/Development/starcraft-sound-effects-for-claude-code/starcraft-sound-router-v3.sh"
if [ -f "$ROUTER" ]; then
    echo "✓ Production router exists: $ROUTER"
    echo "  Executable: $([ -x "$ROUTER" ] && echo "YES" || echo "NO")"
else
    echo "✗ Production router NOT FOUND: $ROUTER"
fi

# Check sounds.json
SOUNDS_JSON="/Users/user/Development/starcraft-sound-effects-for-claude-code/starcraft-sounds.json"
if [ -f "$SOUNDS_JSON" ]; then
    echo "✓ Sounds JSON exists: $SOUNDS_JSON"
    SOUND_DIR=$(jq -r '.base_path // empty' "$SOUNDS_JSON" 2>/dev/null)
    echo "  Sound directory: $SOUND_DIR"
    if [ -d "$SOUND_DIR" ]; then
        echo "  Sound dir exists: YES"
        WAV_COUNT=$(find "$SOUND_DIR" -name "*.wav" 2>/dev/null | wc -l)
        echo "  Number of .wav files: $WAV_COUNT"
    else
        echo "  Sound dir exists: NO - THIS IS A PROBLEM!"
    fi
else
    echo "✗ Sounds JSON NOT FOUND: $SOUNDS_JSON"
fi

# Check if afplay works
echo ""
echo "=== TESTING AFPLAY ==="
if command -v afplay &> /dev/null; then
    echo "✓ afplay is available"
    # Try to play a test sound
    TEST_SOUND="/Users/user/Music/StarCraft/Starcraft1/Terran/Advisor-Annotated/tadUpd00.wav"
    if [ -f "$TEST_SOUND" ]; then
        echo "✓ Test sound file exists: $TEST_SOUND"
        echo "  To test: afplay \"$TEST_SOUND\""
    else
        echo "✗ Test sound file NOT found: $TEST_SOUND"
    fi
else
    echo "✗ afplay command not found"
fi

echo ""
echo "========== END ANALYSIS =========="
