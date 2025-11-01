#!/bin/bash

# Test script for semantic sound routing with centralized config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
SOUND_CONFIG="${SCRIPT_DIR}/sound-config.json"

echo "Testing Centralized Sound Configuration"
echo "========================================"
echo

# Test 1: Verify .env has STARCRAFT_ROOT_DIR
echo "Test 1: Checking .env configuration..."
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ ERROR: .env file not found"
    exit 1
fi

source "$ENV_FILE"

if [ -z "${STARCRAFT_ROOT_DIR:-}" ]; then
    echo "❌ ERROR: STARCRAFT_ROOT_DIR not set in .env"
    exit 1
fi

if [ ! -d "$STARCRAFT_ROOT_DIR" ]; then
    echo "❌ ERROR: Directory not found: $STARCRAFT_ROOT_DIR"
    exit 1
fi

echo "✓ STARCRAFT_ROOT_DIR configured: $STARCRAFT_ROOT_DIR"
echo

# Test 2: Verify sound-config.json exists and is valid
echo "Test 2: Checking sound-config.json..."
if [ ! -f "$SOUND_CONFIG" ]; then
    echo "❌ ERROR: sound-config.json not found"
    exit 1
fi

# Validate JSON structure
if ! jq empty "$SOUND_CONFIG" 2>/dev/null; then
    echo "❌ ERROR: Invalid JSON in sound-config.json"
    exit 1
fi

echo "✓ sound-config.json is valid JSON"
echo

# Test 3: Verify all semantic sound files exist
echo "Test 3: Checking semantic sound files (classes 1-14)..."
MISSING_COUNT=0
for i in {1..14}; do
    RELATIVE_PATH=$(jq -r ".semantic_sounds.\"$i\" // empty" "$SOUND_CONFIG")
    if [ -z "$RELATIVE_PATH" ]; then
        echo "  ⚠ Class $i: No mapping in config"
        MISSING_COUNT=$((MISSING_COUNT + 1))
        continue
    fi

    FULL_PATH="${STARCRAFT_ROOT_DIR}/${RELATIVE_PATH}"
    if [ ! -f "$FULL_PATH" ]; then
        echo "  ❌ Class $i: File not found - $RELATIVE_PATH"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    else
        echo "  ✓ Class $i: OK"
    fi
done

if [ $MISSING_COUNT -gt 0 ]; then
    echo
    echo "⚠ Warning: $MISSING_COUNT semantic sound files are missing"
else
    echo
    echo "✓ All 14 semantic sound files found"
fi
echo

# Test 4: Verify error sound exists
echo "Test 4: Checking error sound file..."
ERROR_SOUND_RELATIVE=$(jq -r '.error_sound // empty' "$SOUND_CONFIG")
if [ -z "$ERROR_SOUND_RELATIVE" ]; then
    echo "❌ ERROR: error_sound not configured in sound-config.json"
    exit 1
fi

ERROR_SOUND_FULL="${STARCRAFT_ROOT_DIR}/${ERROR_SOUND_RELATIVE}"
if [ ! -f "$ERROR_SOUND_FULL" ]; then
    echo "❌ ERROR: Error sound file not found - $ERROR_SOUND_RELATIVE"
    exit 1
fi

echo "✓ Error sound file found: $ERROR_SOUND_RELATIVE"
echo

# Test 5: Test playing a sample sound
echo "Test 5: Testing audio playback..."
echo "Playing class 6 sound (Upgrade Complete)..."

CLASS_6_RELATIVE=$(jq -r '.semantic_sounds."6"' "$SOUND_CONFIG")
CLASS_6_FULL="${STARCRAFT_ROOT_DIR}/${CLASS_6_RELATIVE}"

if [ -f "$CLASS_6_FULL" ]; then
    afplay "$CLASS_6_FULL" &
    echo "✓ Sound playback initiated"
    sleep 2
else
    echo "⚠ Skipping playback test (file not found)"
fi
echo

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Configuration: ✓ Centralized"
echo "Root Directory: ✓ $STARCRAFT_ROOT_DIR"
echo "Sound Config: ✓ sound-config.json"
echo "Semantic Sounds: $((14 - MISSING_COUNT))/14 found"
echo "Error Sound: ✓ Configured"
echo
echo "✓ Centralized configuration is working!"
echo
echo "Both hooks now use:"
echo "  - STARCRAFT_ROOT_DIR from .env (private/portable)"
echo "  - sound-config.json for mappings (version controlled)"
