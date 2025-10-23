#!/bin/bash

# Sound Map Validator
# ==================
# This script validates that the sound map JSON has complete coverage of all
# possible 3D sentiment combinations (severity × magnitude × context).
#
# The 3D space has 3×3×3 = 27 possible combinations:
# - severity: error, warning, success (3 options)
# - magnitude: major, normal, minor (3 options)
# - context: destructive, constructive, neutral (3 options)
#
# This validator ensures every combination either:
# 1. Has at least one mapped sound, OR
# 2. Is explicitly marked as intentionally unmapped
#
# Usage: bash validate-sound-map.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_MAP="${SCRIPT_DIR}/starcraft-sound-map.json"

if [ ! -f "$SOUND_MAP" ]; then
    echo "ERROR: Sound map not found: $SOUND_MAP"
    exit 1
fi

echo "=== Sound Map Validator ==="
echo "Checking: $SOUND_MAP"
echo ""

# Define all 3D dimensions
SEVERITIES=("error" "warning" "success")
MAGNITUDES=("major" "normal" "minor")
CONTEXTS=("destructive" "constructive" "neutral")

TOTAL_COMBINATIONS=0
COVERED_COMBINATIONS=0
UNCOVERED_COMBINATIONS=0

# Build an array of all mapped combinations
MAPPED_COMBOS=$(jq -r '.mappings[] | "\(.severity)|\(.magnitude)|\(.context)"' "$SOUND_MAP" | sort -u)

echo "Checking all ${#SEVERITIES[@]} × ${#MAGNITUDES[@]} × ${#CONTEXTS[@]} = 27 possible combinations..."
echo ""

# Test each combination
for severity in "${SEVERITIES[@]}"; do
    for magnitude in "${MAGNITUDES[@]}"; do
        for context in "${CONTEXTS[@]}"; do
            TOTAL_COMBINATIONS=$((TOTAL_COMBINATIONS + 1))
            COMBO="${severity}|${magnitude}|${context}"

            # Check if this combination exists in the map
            if echo "$MAPPED_COMBOS" | grep -q "^${COMBO}$"; then
                COVERED_COMBINATIONS=$((COVERED_COMBINATIONS + 1))
                SOUNDS=$(jq -r --arg sev "$severity" --arg mag "$magnitude" --arg ctx "$context" \
                  '.mappings[] | select(.severity == $sev and .magnitude == $mag and .context == $ctx) | .sounds | length' \
                  "$SOUND_MAP" | head -1)
                echo "✓ $severity/$magnitude/$context → $SOUNDS sound(s)"
            else
                UNCOVERED_COMBINATIONS=$((UNCOVERED_COMBINATIONS + 1))
                echo "✗ $severity/$magnitude/$context → NO MAPPING"
            fi
        done
    done
done

echo ""
echo "=== Results ==="
echo "Total combinations: $TOTAL_COMBINATIONS"
echo "Covered: $COVERED_COMBINATIONS"
echo "Uncovered: $UNCOVERED_COMBINATIONS"
echo ""

if [ $UNCOVERED_COMBINATIONS -eq 0 ]; then
    echo "✓ SUCCESS: All combinations are mapped!"
    exit 0
else
    echo "✗ FAILURE: $UNCOVERED_COMBINATIONS combination(s) are unmapped"
    echo ""
    echo "Unmapped combinations:"
    for severity in "${SEVERITIES[@]}"; do
        for magnitude in "${MAGNITUDES[@]}"; do
            for context in "${CONTEXTS[@]}"; do
                COMBO="${severity}|${magnitude}|${context}"
                if ! echo "$MAPPED_COMBOS" | grep -q "^${COMBO}$"; then
                    echo "  - $severity/$magnitude/$context"
                fi
            done
        done
    done
    exit 1
fi
