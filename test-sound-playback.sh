#!/bin/bash
# Test Module 1: Sound Playback
# Tests if afplay works and sound files exist

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

echo "=== Testing Sound Playback Module ==="
echo ""

# Load environment
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ FAIL: Missing .env file"
    exit 1
fi

export $(grep -v '^#' "$ENV_FILE" | xargs)

# Check SOUND_DIR exists
if [ -z "${SOUND_DIR:-}" ]; then
    echo "❌ FAIL: SOUND_DIR not set in .env"
    exit 1
fi

if [ ! -d "$SOUND_DIR" ]; then
    echo "❌ FAIL: Sound directory not found: $SOUND_DIR"
    exit 1
fi

echo "✅ Sound directory exists: $SOUND_DIR"
echo ""

# Check each sound file from starcraft-sounds.json
echo "Checking sound files..."
MISSING_COUNT=0
FOUND_COUNT=0

for class_id in {1..14}; do
    sound_file=$(jq -r ".\"$class_id\" // empty" "${SCRIPT_DIR}/starcraft-sounds.json")

    if [ -z "$sound_file" ]; then
        echo "⚠️  Class $class_id: No mapping in starcraft-sounds.json"
        continue
    fi

    full_path="${SOUND_DIR}/${sound_file}"

    if [ -f "$full_path" ]; then
        echo "✅ Class $class_id: $sound_file"
        FOUND_COUNT=$((FOUND_COUNT + 1))
    else
        echo "❌ Class $class_id: MISSING $sound_file"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done

echo ""
echo "Summary: $FOUND_COUNT found, $MISSING_COUNT missing"
echo ""

# Test afplay with one sound
if [ $FOUND_COUNT -gt 0 ]; then
    TEST_SOUND=$(jq -r '.["5"] // .["1"] // empty' "${SCRIPT_DIR}/starcraft-sounds.json")
    if [ -n "$TEST_SOUND" ]; then
        echo "Testing playback with: $TEST_SOUND"
        TEST_PATH="${SOUND_DIR}/${TEST_SOUND}"

        if afplay "$TEST_PATH" 2>&1; then
            echo "✅ Sound playback works!"
        else
            echo "❌ FAIL: afplay failed"
            exit 1
        fi
    fi
fi

echo ""
echo "=== Sound Playback Module: PASSED ==="
