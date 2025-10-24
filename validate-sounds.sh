#!/bin/bash

# Simple sound file validator for StarCraft Sound Router
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_MAP_FILE="${SCRIPT_DIR}/starcraft-sounds.json"
ENV_FILE="${SCRIPT_DIR}/.env"

# Load environment variables - required
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}✗ Missing .env file. Please copy .env.example to .env and configure it.${NC}"
    exit 1
fi
export $(grep -v '^#' "$ENV_FILE" | xargs)

# Check required environment variables
if [ -z "${SOUND_DIR:-}" ]; then
    echo -e "${RED}✗ SOUND_DIR not set in .env file${NC}"
    exit 1
fi

echo "Sound File Validator"
echo "===================="

if [ ! -f "$SOUND_MAP_FILE" ]; then
    echo -e "${RED}✗ Sound map not found: $SOUND_MAP_FILE${NC}"
    exit 1
fi

if [ ! -d "$SOUND_DIR" ]; then
    echo -e "${RED}✗ Sound directory not found: $SOUND_DIR${NC}"
    exit 1
fi

echo "Checking sound files in: $SOUND_DIR"
echo

# Check each sound file
MISSING=0
FOUND=0

for i in {1..14}; do
    SOUND_FILE=$(jq -r ".\"$i\" // empty" "$SOUND_MAP_FILE")

    if [ -z "$SOUND_FILE" ]; then
        echo -e "${RED}✗ Class $i: No sound mapped${NC}"
        MISSING=$((MISSING + 1))
    elif [ -f "$SOUND_DIR/$SOUND_FILE" ]; then
        echo -e "${GREEN}✓ Class $i: $SOUND_FILE${NC}"
        FOUND=$((FOUND + 1))
    else
        echo -e "${RED}✗ Class $i: $SOUND_FILE (not found)${NC}"
        MISSING=$((MISSING + 1))
    fi
done

echo
echo "Summary: $FOUND found, $MISSING missing"

[ $MISSING -eq 0 ] && exit 0 || exit 1