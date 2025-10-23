#!/bin/bash

# StarCraft Sound Map Validator v3.0
# Validates the 14-class mapping configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_MAP_FILE="${SCRIPT_DIR}/starcraft-sounds.json"
ENV_FILE="${SCRIPT_DIR}/.env"
SOUND_DIR="/Users/user/Music/StarCraft/Starcraft1/Terran/Advisor-Annotated"

echo "======================================"
echo "StarCraft Sound Map Validator v3.0"
echo "======================================"
echo

# Check if sound map file exists
if [ ! -f "$SOUND_MAP_FILE" ]; then
    echo -e "${RED}✗ Sound map file not found: $SOUND_MAP_FILE${NC}"
    exit 1
fi

echo "Checking configuration..."
echo

# Validate JSON structure
if ! jq empty "$SOUND_MAP_FILE" 2>/dev/null; then
    echo -e "${RED}✗ Invalid JSON in $SOUND_MAP_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Valid JSON structure${NC}"

# Check all 14 classes are mapped
echo
echo "Validating class mappings..."

ERRORS=0
WARNINGS=0

for i in {1..14}; do
    # Check if class exists
    CLASS_EXISTS=$(jq -r ".sounds.\"$i\" // empty" "$SOUND_MAP_FILE")

    if [ -z "$CLASS_EXISTS" ]; then
        echo -e "${RED}✗ Missing class $i${NC}"
        ((ERRORS++))
        continue
    fi

    # Get class details
    SOUND_FILE=$(jq -r ".sounds.\"$i\".file // empty" "$SOUND_MAP_FILE")
    CLASS_NAME=$(jq -r ".sounds.\"$i\".class // empty" "$SOUND_MAP_FILE")
    CLASS_DESC=$(jq -r ".sounds.\"$i\".description // empty" "$SOUND_MAP_FILE")

    # Check if sound file is specified
    if [ -z "$SOUND_FILE" ]; then
        echo -e "${RED}✗ Class $i missing sound file${NC}"
        ((ERRORS++))
        continue
    fi

    # Check if sound file exists
    FULL_PATH="${SOUND_DIR}/${SOUND_FILE}"
    if [ ! -f "$FULL_PATH" ]; then
        echo -e "${YELLOW}⚠ Class $i: Sound file not found: $SOUND_FILE${NC}"
        ((WARNINGS++))
    else
        echo -e "${GREEN}✓ Class $i: $CLASS_NAME - $SOUND_FILE${NC}"
    fi
done

# Check for duplicate sound files
echo
echo "Checking for duplicate mappings..."

DUPLICATES=$(jq -r '.sounds[].file' "$SOUND_MAP_FILE" | sort | uniq -d)

if [ -n "$DUPLICATES" ]; then
    echo -e "${YELLOW}⚠ Duplicate sound files found:${NC}"
    echo "$DUPLICATES"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ No duplicate sound mappings${NC}"
fi

# Check environment configuration
echo
echo "Checking environment..."

if [ -f "$ENV_FILE" ]; then
    if grep -q "ANTHROPIC_API_KEY" "$ENV_FILE"; then
        echo -e "${GREEN}✓ API key configured in .env${NC}"
    else
        echo -e "${YELLOW}⚠ No ANTHROPIC_API_KEY in .env (will use default classification)${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠ No .env file found (will use default classification)${NC}"
    ((WARNINGS++))
fi

# Check sound directory
echo
echo "Checking sound directory..."

if [ -d "$SOUND_DIR" ]; then
    SOUND_COUNT=$(ls -1 "$SOUND_DIR"/*.wav 2>/dev/null | wc -l)
    echo -e "${GREEN}✓ Sound directory exists with $SOUND_COUNT .wav files${NC}"
else
    echo -e "${RED}✗ Sound directory not found: $SOUND_DIR${NC}"
    ((ERRORS++))
fi

# Check afplay command
echo
echo "Checking audio playback..."

if command -v afplay &> /dev/null; then
    echo -e "${GREEN}✓ afplay command available${NC}"
else
    echo -e "${RED}✗ afplay command not found (required for macOS audio)${NC}"
    ((ERRORS++))
fi

# Display class distribution
echo
echo "Class Distribution:"
echo "==================="

jq -r '.sounds | to_entries | .[] | "\(.key | tonumber | tostring | .[0:2] | . + " " * (2 - length)): \(.value.class)"' "$SOUND_MAP_FILE" | column -t -s ':'

# Summary
echo
echo "======================================"
echo "Validation Summary"
echo "======================================"

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed! System ready.${NC}"
    else
        echo -e "${YELLOW}⚠ Validation completed with $WARNINGS warning(s)${NC}"
        echo "The system will work but some features may be limited."
    fi
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo "Please fix the errors before using the system."
    exit 1
fi