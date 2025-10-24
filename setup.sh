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
ENV_FILE="$SCRIPT_DIR/.env"

# Step 1: Check/Create .env file from template
echo -e "${YELLOW}Step 1: Environment Configuration...${NC}"
if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        echo "No .env file found. Creating from .env.example..."
        cp "$SCRIPT_DIR/.env.example" "$ENV_FILE"
        echo -e "${GREEN}✓ Created .env file from template${NC}"
    else
        echo -e "${RED}✗ No .env.example found! Creating basic .env file...${NC}"
        touch "$ENV_FILE"
    fi
fi

# Step 2: Configure API Key
echo -e "${YELLOW}Step 2: API Key Configuration...${NC}"
if grep -q "^ANTHROPIC_API_KEY=" "$ENV_FILE" && ! grep -q "^ANTHROPIC_API_KEY=your-api-key-here" "$ENV_FILE"; then
    echo -e "${GREEN}✓ API key already configured${NC}"
    SKIP_API_TEST=false
else
    echo "Please enter your Anthropic API key (get one at https://console.anthropic.com/):"
    read -r API_KEY
    if [ -n "$API_KEY" ]; then
        if grep -q "^ANTHROPIC_API_KEY=" "$ENV_FILE"; then
            sed -i.bak "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=$API_KEY|" "$ENV_FILE"
        else
            echo "ANTHROPIC_API_KEY=$API_KEY" >> "$ENV_FILE"
        fi
        echo -e "${GREEN}✓ API key saved to .env${NC}"
        SKIP_API_TEST=false
    else
        echo -e "${RED}✗ No API key provided. Sound effects will not work!${NC}"
        SKIP_API_TEST=true
    fi
fi
echo

# Step 3: Configure Sound Directory
echo -e "${YELLOW}Step 3: Sound Directory Configuration...${NC}"
# Load current environment
source "$ENV_FILE" 2>/dev/null || true

if [ -n "${SOUND_DIR:-}" ] && [ -d "$SOUND_DIR" ]; then
    echo -e "${GREEN}✓ Sound directory already configured: $SOUND_DIR${NC}"
else
    echo "Sound directory is not configured or doesn't exist."
    DEFAULT_SOUND_PATH="/Users/$(whoami)/Music/StarCraft/Starcraft1/Terran/Advisor-Annotated"
    echo "Suggested default path: $DEFAULT_SOUND_PATH"
    echo
    echo "1) Use default path"
    echo "2) Enter custom path"
    echo "3) Skip (configure later)"
    read -r SOUND_CHOICE

    case "$SOUND_CHOICE" in
        1)
            SOUND_DIR="$DEFAULT_SOUND_PATH"
            ;;
        2)
            echo "Enter the full path to your sound files directory:"
            read -r SOUND_DIR
            ;;
        3)
            echo -e "${YELLOW}⚠ Skipping sound directory configuration${NC}"
            SOUND_DIR=""
            ;;
        *)
            echo -e "${YELLOW}⚠ Invalid choice, skipping${NC}"
            SOUND_DIR=""
            ;;
    esac

    if [ -n "$SOUND_DIR" ]; then
        if grep -q "^SOUND_DIR=" "$ENV_FILE"; then
            sed -i.bak "s|^SOUND_DIR=.*|SOUND_DIR=$SOUND_DIR|" "$ENV_FILE"
        else
            echo "SOUND_DIR=$SOUND_DIR" >> "$ENV_FILE"
        fi
        echo -e "${GREEN}✓ Sound directory saved to .env${NC}"
    fi
fi

# Verify sound files exist
if [ -n "${SOUND_DIR:-}" ] && [ -d "$SOUND_DIR" ]; then
    SOUND_COUNT=$(ls -1 "$SOUND_DIR"/*.wav 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SOUND_COUNT" -ge 14 ]; then
        echo -e "${GREEN}✓ Found $SOUND_COUNT .wav files${NC}"
    else
        echo -e "${YELLOW}⚠ Found only $SOUND_COUNT .wav files (need 14)${NC}"
        echo "Download StarCraft Brood War Terran Advisor sounds"
    fi
else
    echo -e "${YELLOW}⚠ Sound directory not configured or doesn't exist${NC}"
fi
echo

# Step 4: Test API Connection
if [ "$SKIP_API_TEST" = false ]; then
    echo -e "${YELLOW}Step 4: Testing API Connection...${NC}"
    # Reload environment to get latest values
    source "$ENV_FILE" 2>/dev/null || true

    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        echo "Testing Claude API with a simple classification..."

        # Test API call
        RESPONSE=$(curl -s -X POST https://api.anthropic.com/v1/messages \
            -H "x-api-key: ${ANTHROPIC_API_KEY}" \
            -H "anthropic-version: 2023-06-01" \
            -H "content-type: application/json" \
            -d '{
                "model": "claude-3-haiku-20240307",
                "max_tokens": 20,
                "temperature": 0.3,
                "messages": [{
                    "role": "user",
                    "content": "Classify: \"Task completed successfully\" into class 1-14. Classes: 1=Need clarification 2=Need permissions 3=Need user choice 4=Search failed 5=Simple edit done 6=Feature complete 7=Analysis complete 8=Cleanup complete 9=Deployed successfully 10=Partially done 11=Issues found 12=Tests failing 13=System broken 14=Cannot proceed. Return only: {\"class\": N}"
                }]
            }' 2>/dev/null)

        if echo "$RESPONSE" | grep -q '"class"' || echo "$RESPONSE" | grep -q "class"; then
            echo -e "${GREEN}✓ API connection successful!${NC}"
            CLASS=$(echo "$RESPONSE" | grep -o '[0-9]\+' | head -1)
            echo "  Test classification returned: Class $CLASS"
        elif echo "$RESPONSE" | grep -q "invalid_api_key"; then
            echo -e "${RED}✗ Invalid API key. Please check your key.${NC}"
        elif echo "$RESPONSE" | grep -q "rate_limit"; then
            echo -e "${YELLOW}⚠ Rate limit reached, but API key is valid${NC}"
        else
            echo -e "${YELLOW}⚠ Unexpected API response. Key might be valid.${NC}"
        fi
    else
        echo -e "${RED}✗ No API key configured${NC}"
    fi
else
    echo -e "${YELLOW}Step 4: Skipping API test (no API key)${NC}"
fi
echo

# Step 5: Configure Claude Code Hook
echo -e "${YELLOW}Step 5: Configuring Claude Code Hook...${NC}"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
HOOK_SCRIPT="$SCRIPT_DIR/starcraft-sound-router.sh"

if [ -f "$CLAUDE_SETTINGS" ]; then
    echo "Current Claude settings found."
    echo "Would you like to update them to use this sound system? (y/n)"
    read -r UPDATE_CHOICE

    if [[ "$UPDATE_CHOICE" == "y" ]]; then
        # Backup current settings
        cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.backup.$(date +%s)"

        # Update settings using jq
        jq --arg cmd "$HOOK_SCRIPT" '
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
        "command": "'$HOOK_SCRIPT'"
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
        "command": "$HOOK_SCRIPT"
      }]
    }]
  }
}
EOF
    echo -e "${GREEN}✓ Claude settings created${NC}"
fi
echo

# Step 6: Validate Configuration
echo -e "${YELLOW}Step 6: Final Validation...${NC}"
source "$ENV_FILE" 2>/dev/null || true

ISSUES=0
if [ -z "${ANTHROPIC_API_KEY:-}" ] || [[ "$ANTHROPIC_API_KEY" == "your-api-key-here" ]]; then
    echo -e "${RED}✗ API key not configured${NC}"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✓ API key configured${NC}"
fi

if [ -z "${SOUND_DIR:-}" ]; then
    echo -e "${RED}✗ Sound directory not configured${NC}"
    ISSUES=$((ISSUES + 1))
elif [ ! -d "$SOUND_DIR" ]; then
    echo -e "${RED}✗ Sound directory doesn't exist: $SOUND_DIR${NC}"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✓ Sound directory exists${NC}"
fi

if [ ! -f "$HOOK_SCRIPT" ]; then
    echo -e "${YELLOW}⚠ Note: starcraft-sound-router.sh will be created after renaming${NC}"
fi
echo

# Final message
if [ $ISSUES -eq 0 ]; then
    echo -e "${BLUE}======================================"
    echo -e "${GREEN}🎮 Setup Complete!${NC}"
    echo "======================================${NC}"
    echo
    echo "Next steps:"
    echo "1. Restart Claude Code to apply hook changes"
    echo "2. Try asking Claude something to hear the sounds!"
    echo
    echo -e "${GREEN}Ready for deployment, Commander!${NC}"
else
    echo -e "${BLUE}======================================"
    echo -e "${YELLOW}⚠ Setup Incomplete${NC}"
    echo "======================================${NC}"
    echo
    echo "Please fix the issues above, then:"
    echo "1. Restart Claude Code"
    echo "2. Test the sound system"
    echo
    echo "Run this setup again if needed: ./setup.sh"
fi