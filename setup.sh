#!/bin/bash

# StarCraft Sound Effects for Claude Code - Setup Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================"
echo "🎮 StarCraft Sound Effects Setup"
echo "======================================${NC}"
echo

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Check for .env file
echo -e "${YELLOW}Step 1: Checking API key configuration...${NC}"
if [ -f "$SCRIPT_DIR/.env" ]; then
    if grep -q "ANTHROPIC_API_KEY" "$SCRIPT_DIR/.env"; then
        echo -e "${GREEN}✓ API key already configured${NC}"
    else
        echo -e "${YELLOW}⚠ .env exists but missing ANTHROPIC_API_KEY${NC}"
        echo "Please add your API key to .env file"
    fi
else
    echo -e "${YELLOW}Creating .env file...${NC}"
    echo "Please enter your Anthropic API key (or press Enter to skip):"
    read -r API_KEY
    if [ -n "$API_KEY" ]; then
        echo "ANTHROPIC_API_KEY=$API_KEY" > "$SCRIPT_DIR/.env"
        echo -e "${GREEN}✓ API key saved to .env${NC}"
    else
        echo -e "${YELLOW}⚠ Skipped API key (will use fallback classification)${NC}"
    fi
fi
echo

# Step 2: Check for sound files
echo -e "${YELLOW}Step 2: Checking sound files...${NC}"
# Load SOUND_DIR from .env if it exists
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Use default path only as a suggestion, not as actual value
DEFAULT_SOUND_PATH="/Users/$(whoami)/Music/StarCraft/Starcraft1/Terran/Advisor-Annotated"

if [ -z "${SOUND_DIR:-}" ]; then
    echo "SOUND_DIR is not configured in .env file."
    echo "Suggested default path: $DEFAULT_SOUND_PATH"
    echo
    echo "Would you like to use this path? (y/n)"
    read -r USE_DEFAULT
    if [[ "$USE_DEFAULT" == "y" ]]; then
        SOUND_DIR="$DEFAULT_SOUND_PATH"
        echo "SOUND_DIR=$SOUND_DIR" >> "$ENV_FILE"
        echo -e "${GREEN}✓ Added SOUND_DIR to .env${NC}"
    else
        echo "Please enter your sound directory path:"
        read -r SOUND_DIR
        echo "SOUND_DIR=$SOUND_DIR" >> "$ENV_FILE"
        echo -e "${GREEN}✓ Added SOUND_DIR to .env${NC}"
    fi
fi

if [ -d "$SOUND_DIR" ] && [ "$(ls -A "$SOUND_DIR"/*.wav 2>/dev/null | wc -l)" -ge 14 ]; then
    echo -e "${GREEN}✓ Sound files found at default location${NC}"
else
    echo -e "${YELLOW}⚠ Sound files not found at: $SOUND_DIR${NC}"
    echo
    echo "You need to obtain the StarCraft sound files:"
    echo "1. Search for 'StarCraft Brood War Terran Advisor sounds'"
    echo "2. Place the 14 .wav files in:"
    echo "   $SOUND_DIR"
    echo
    echo "Or specify a custom path? (y/n)"
    read -r CUSTOM_PATH_CHOICE
    if [[ "$CUSTOM_PATH_CHOICE" == "y" ]]; then
        echo "Enter the full path to your sound files directory:"
        read -r CUSTOM_SOUND_DIR
        if [ -d "$CUSTOM_SOUND_DIR" ]; then
            # Update or add SOUND_DIR in .env file
            if grep -q "^SOUND_DIR=" "$ENV_FILE" 2>/dev/null; then
                # Update existing SOUND_DIR
                sed -i.bak "s|^SOUND_DIR=.*|SOUND_DIR=$CUSTOM_SOUND_DIR|" "$ENV_FILE"
            else
                # Add SOUND_DIR to .env
                echo "SOUND_DIR=$CUSTOM_SOUND_DIR" >> "$ENV_FILE"
            fi
            echo -e "${GREEN}✓ Updated sound directory path in .env${NC}"
        else
            echo -e "${RED}✗ Directory not found: $CUSTOM_SOUND_DIR${NC}"
        fi
    fi
fi
echo

# Step 3: Check Claude settings
echo -e "${YELLOW}Step 3: Configuring Claude Code...${NC}"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

if [ -f "$CLAUDE_SETTINGS" ]; then
    echo "Current Claude settings found."
    echo "Would you like to update them to use this sound system? (y/n)"
    read -r UPDATE_CHOICE

    if [[ "$UPDATE_CHOICE" == "y" ]]; then
        # Backup current settings
        cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.backup.$(date +%s)"

        # Update settings using jq
        HOOK_COMMAND="$SCRIPT_DIR/starcraft-sound-router-v3.sh"

        jq --arg cmd "$HOOK_COMMAND" '
            .hooks = (.hooks // {}) |
            .hooks.Stop = [
                {
                    "hooks": [
                        {
                            "type": "command",
                            "command": $cmd
                        }
                    ]
                }
            ]
        ' "$CLAUDE_SETTINGS" > tmp.json && mv tmp.json "$CLAUDE_SETTINGS"

        echo -e "${GREEN}✓ Claude settings updated (backup created)${NC}"
    else
        echo -e "${YELLOW}Skipped Claude settings update${NC}"
        echo "To manually update, add this to $CLAUDE_SETTINGS:"
        echo '
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "'$SCRIPT_DIR'/starcraft-sound-router-v3.sh"
      }]
    }]
  }
}'
    fi
else
    echo -e "${YELLOW}Claude settings not found. Creating new settings...${NC}"
    mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
    cat > "$CLAUDE_SETTINGS" << EOF
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "$SCRIPT_DIR/starcraft-sound-router-v3.sh"
      }]
    }]
  }
}
EOF
    echo -e "${GREEN}✓ Claude settings created${NC}"
fi
echo

# Step 4: Validate installation
echo -e "${YELLOW}Step 4: Validating installation...${NC}"
"$SCRIPT_DIR/validate-sound-map-v3.sh"
echo

# Final message
echo -e "${BLUE}======================================"
echo "🎮 Setup Complete!"
echo "======================================${NC}"
echo
echo "Next steps:"
echo "1. Make sure you have the sound files in place"
echo "2. Restart Claude Code if it's running"
echo "3. Try asking Claude something to hear the sounds!"
echo
echo -e "${GREEN}Ready for deployment, Commander!${NC}"