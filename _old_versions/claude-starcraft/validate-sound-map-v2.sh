#!/bin/bash

# Validator for starcraft-sound-map v2.0
# Checks that all 27 combinations (3x3x3) are covered
# Checks that all 14 sounds are used at least once

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAP_FILE="$SCRIPT_DIR/starcraft-sound-map-new.json"

# Check if map file exists
if [[ ! -f "$MAP_FILE" ]]; then
    echo "ERROR: Map file not found: $MAP_FILE"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed"
    echo "Install with: brew install jq"
    exit 1
fi

echo "=========================================="
echo "StarCraft Sound Map v2.0 Validator"
echo "=========================================="
echo ""

# Define all possible values
MODES=("question" "action" "report")
TYPES=("constructive" "destructive" "analytical")
OUTCOMES=("success" "problem" "neutral")

# All 14 available sounds
ALL_SOUNDS=(
    "tadErr00-not-enough-minerals.wav"
    "tadErr01-insufficient-vespene-gas.wav"
    "tadErr02-additional-supply-depots-required.wav"
    "tadErr03-landing-sequence-interrupted.wav"
    "tadErr04-unacceptable-landing-zone.wav"
    "TAdErr06-not-enough-energy.wav"
    "tadUpd00-base-is-under-attack.wav"
    "tadUpd01-your-forces-are-under-attack.wav"
    "tadUpd02-research-complete.wav"
    "tadUpd03-addon-complete.wav"
    "tadUPD04-nuclear-launch-detected.wav"
    "tadUPD05-abandoning-auxiliary-structure.wav"
    "tadUPD06-upgrade-complete.wav"
    "TAdUpd07-nuclear-missile-ready.wav"
)

# Check dimension coverage
echo "Checking dimension coverage..."
echo ""

total_combinations=0
covered_combinations=0
uncovered=()

for mode in "${MODES[@]}"; do
    for type in "${TYPES[@]}"; do
        for outcome in "${OUTCOMES[@]}"; do
            ((total_combinations++))

            # Check if this combination exists in the map
            sounds=$(jq -r ".mappings[] | select(.mode == \"$mode\" and .type == \"$type\" and .outcome == \"$outcome\") | .sounds[]" "$MAP_FILE" 2>/dev/null)

            if [[ -n "$sounds" ]]; then
                ((covered_combinations++))
                sound_count=$(echo "$sounds" | wc -l | tr -d ' ')
                echo "✓ $mode/$type/$outcome → $sound_count sound(s)"
            else
                uncovered+=("$mode/$type/$outcome")
                echo "✗ $mode/$type/$outcome → NOT MAPPED"
            fi
        done
    done
done

echo ""
echo "=========================================="
echo "Coverage Summary"
echo "=========================================="
echo "Total combinations: $total_combinations"
echo "Covered: $covered_combinations"
echo "Uncovered: $((total_combinations - covered_combinations))"
echo ""

if [[ ${#uncovered[@]} -gt 0 ]]; then
    echo "❌ INCOMPLETE COVERAGE!"
    echo "Missing combinations:"
    for combo in "${uncovered[@]}"; do
        echo "  - $combo"
    done
    echo ""
    COVERAGE_OK=false
else
    echo "✅ All combinations covered!"
    echo ""
    COVERAGE_OK=true
fi

# Check sound usage
echo "=========================================="
echo "Sound Usage Analysis"
echo "=========================================="
echo ""

# Get all sounds used in the mapping
used_sounds=$(jq -r '.mappings[].sounds[]' "$MAP_FILE" | sort -u)

unused_sounds=()
for sound in "${ALL_SOUNDS[@]}"; do
    if echo "$used_sounds" | grep -q "^$sound$"; then
        # Count how many times this sound appears
        count=$(jq -r '.mappings[].sounds[]' "$MAP_FILE" | grep -c "^$sound$")
        echo "✓ $sound → used $count time(s)"
    else
        unused_sounds+=("$sound")
        echo "✗ $sound → NEVER USED"
    fi
done

echo ""
echo "=========================================="
echo "Sound Usage Summary"
echo "=========================================="
echo "Total available sounds: ${#ALL_SOUNDS[@]}"
echo "Used sounds: $((${#ALL_SOUNDS[@]} - ${#unused_sounds[@]}))"
echo "Unused sounds: ${#unused_sounds[@]}"
echo ""

if [[ ${#unused_sounds[@]} -gt 0 ]]; then
    echo "⚠️  Some sounds are never used:"
    for sound in "${unused_sounds[@]}"; do
        echo "  - $sound"
    done
    echo ""
    SOUND_USAGE_OK=false
else
    echo "✅ All sounds are used at least once!"
    echo ""
    SOUND_USAGE_OK=true
fi

# Check for sounds that don't exist
echo "=========================================="
echo "Sound File Existence Check"
echo "=========================================="
echo ""

SOUND_DIR="/Users/user/Music/StarCraft/Starcraft1/Terran/Advisor-Annotated"
missing_files=()

for sound in "${ALL_SOUNDS[@]}"; do
    sound_path="$SOUND_DIR/$sound"
    if [[ -f "$sound_path" ]]; then
        echo "✓ $sound exists"
    else
        missing_files+=("$sound")
        echo "✗ $sound NOT FOUND"
    fi
done

echo ""
if [[ ${#missing_files[@]} -gt 0 ]]; then
    echo "❌ Some sound files are missing from $SOUND_DIR"
    FILES_OK=false
else
    echo "✅ All sound files found!"
    FILES_OK=true
fi
echo ""

# JSON validity
echo "=========================================="
echo "JSON Structure Validation"
echo "=========================================="
echo ""

if jq empty "$MAP_FILE" 2>/dev/null; then
    echo "✅ JSON is valid!"
    JSON_OK=true
else
    echo "❌ JSON is invalid!"
    JSON_OK=false
fi
echo ""

# Final result
echo "=========================================="
echo "FINAL RESULT"
echo "=========================================="
echo ""

if $COVERAGE_OK && $SOUND_USAGE_OK && $FILES_OK && $JSON_OK; then
    echo "🎉 SUCCESS - All validations passed!"
    echo ""
    echo "✅ All 27 combinations are mapped"
    echo "✅ All 14 sounds are used"
    echo "✅ All sound files exist"
    echo "✅ JSON structure is valid"
    echo ""
    echo "The mapping system is ready to use!"
    exit 0
else
    echo "❌ FAILURE - Some validations failed"
    echo ""
    [[ $COVERAGE_OK = false ]] && echo "❌ Incomplete combination coverage"
    [[ $SOUND_USAGE_OK = false ]] && echo "⚠️  Not all sounds are used"
    [[ $FILES_OK = false ]] && echo "❌ Some sound files are missing"
    [[ $JSON_OK = false ]] && echo "❌ JSON structure is invalid"
    echo ""
    echo "Please review the errors above and fix the mapping."
    exit 1
fi
