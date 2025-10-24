#!/bin/bash

# StarCraft Sound Router (AI Version)
# Uses Claude Haiku to intelligently select sounds based on message context

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_JSON="${SCRIPT_DIR}/starcraft-sounds.json"
SOUND_MAP="${SCRIPT_DIR}/starcraft-sound-map.json"

# Read hook input from stdin (JSON format)
HOOK_INPUT=$(cat)

# Parse JSON input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")

# Expand tilde in transcript path
if [[ "$TRANSCRIPT_PATH" == "~"* ]]; then
    TRANSCRIPT_PATH="${HOME}${TRANSCRIPT_PATH:1}"
fi

# Prevent infinite loops
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# Debug mode and logging
DEBUG="${STARCRAFT_DEBUG:-1}"
LOG_FILE="${SCRIPT_DIR}/router.log"

debug_log() {
    local msg="[$(date '+%H:%M:%S')] $*"
    echo "$msg" >> "$LOG_FILE"
    if [ "$DEBUG" = "1" ]; then
        echo "$msg" >&2
    fi
}

debug_log "Starting StarCraft sound router (AI mode)"
debug_log "Hook input: $HOOK_INPUT"
debug_log "Transcript path: $TRANSCRIPT_PATH"
debug_log "Stop hook active: $STOP_HOOK_ACTIVE"

# Extract Claude's latest response
if [ -z "$TRANSCRIPT_PATH" ]; then
    debug_log "Transcript path is empty"
    exit 0
fi

if [ ! -f "$TRANSCRIPT_PATH" ]; then
    debug_log "Transcript file does not exist: $TRANSCRIPT_PATH"
    exit 0
fi

# Extract last assistant message with text content (checking last 50 messages)
LAST_ASSISTANT_MESSAGE=""
TEMP_MESSAGES=$(grep '"type":"assistant"' "$TRANSCRIPT_PATH" | tail -50)
while IFS= read -r line; do
    TEXT=$(echo "$line" | jq -r '.message.content[] | select(.type == "text") | .text' 2>/dev/null)
    if [ -n "$TEXT" ] && [ "$TEXT" != "null" ]; then
        LAST_ASSISTANT_MESSAGE="$TEXT"
    fi
done <<< "$TEMP_MESSAGES"

if [ -z "$LAST_ASSISTANT_MESSAGE" ] || [ "$LAST_ASSISTANT_MESSAGE" = "null" ]; then
    debug_log "No assistant message found"
    exit 0
fi

debug_log "Message length: ${#LAST_ASSISTANT_MESSAGE}"

# Get base path
BASE_PATH=$(jq -r '.base_path' "$SOUNDS_JSON")

# Create prompt for Haiku to analyze the message
PROMPT="Analyze this Claude Code assistant response across 3 dimensions.

Message to analyze:
\`\`\`
${LAST_ASSISTANT_MESSAGE}
\`\`\`

Rate on these 3 dimensions:

1. **severity**: What is the outcome?
   - \"error\": Errors, failures, problems, things went wrong
   - \"warning\": Warnings, issues detected, recommendations, things need attention
   - \"success\": Success, completion, confirmation, things went well

2. **magnitude**: How significant is this?
   - \"major\": Critical/catastrophic issues, big feature completions, major milestones
   - \"normal\": Regular tasks, typical bugs fixed, standard operations
   - \"minor\": Simple responses, quick confirmations, trivial actions

3. **context**: What kind of action is this about?
   - \"destructive\": Deletions, data loss, removals, things being destroyed/abandoned
   - \"constructive\": Building, creating, implementing, fixing, things being made
   - \"neutral\": Information, status updates, questions, general responses

Return ONLY valid JSON (no markdown, no explanation):
{\"severity\": \"error|warning|success\", \"magnitude\": \"major|normal|minor\", \"context\": \"destructive|constructive|neutral\"}"

debug_log "Calling Claude Haiku API for sentiment analysis..."

# Load API key from environment or .env file
ENV_FILE="${SCRIPT_DIR}/.env"
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    debug_log "No API key found, using default analysis"
    ANALYSIS='{"severity": "success", "magnitude": "minor", "context": "neutral"}'
else
    # Call Haiku via API (much faster than spawning claude code process)
    API_REQUEST=$(cat <<EOF
{
  "model": "claude-3-haiku-20240307",
  "max_tokens": 100,
  "messages": [{
    "role": "user",
    "content": $(echo "$PROMPT" | jq -Rs .)
  }]
}
EOF
)

    HAIKU_RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
      -H "x-api-key: $ANTHROPIC_API_KEY" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d "$API_REQUEST" 2>/dev/null)

    debug_log "API response: $HAIKU_RESPONSE"

    # Extract text content from API response
    HAIKU_TEXT=$(echo "$HAIKU_RESPONSE" | jq -r '.content[0].text // ""' 2>/dev/null)
    debug_log "Extracted text: $HAIKU_TEXT"

    # Extract JSON from response (handle multiline JSON)
    ANALYSIS=$(echo "$HAIKU_TEXT" | jq -c 'select(.severity) | {severity, magnitude, context}' 2>/dev/null || echo "")
fi

if [ -z "$ANALYSIS" ]; then
    debug_log "Failed to parse Haiku response, using default"
    ANALYSIS='{"severity": "success", "magnitude": "minor", "context": "neutral"}'
fi

debug_log "Parsed analysis: $ANALYSIS"

# Extract dimensions
SEVERITY=$(echo "$ANALYSIS" | jq -r '.severity // "success"')
MAGNITUDE=$(echo "$ANALYSIS" | jq -r '.magnitude // "minor"')
CONTEXT=$(echo "$ANALYSIS" | jq -r '.context // "neutral"')

debug_log "Dimensions - severity: $SEVERITY, magnitude: $MAGNITUDE, context: $CONTEXT"

# Find matching sounds from the map
MATCHING_SOUNDS=$(jq -r --arg sev "$SEVERITY" --arg mag "$MAGNITUDE" --arg ctx "$CONTEXT" \
  '.mappings[] | select(.severity == $sev and .magnitude == $mag and .context == $ctx) | .sounds[]' \
  "$SOUND_MAP" 2>/dev/null || echo "")

if [ -z "$MATCHING_SOUNDS" ]; then
    debug_log "No matching sounds found, using default"
    SOUND_FILE=$(jq -r '.default' "$SOUND_MAP")
else
    # Count and randomly select one (bash 3.2 compatible)
    SOUND_COUNT=$(echo "$MATCHING_SOUNDS" | wc -l | tr -d ' ')
    debug_log "Found $SOUND_COUNT matching sound(s)"

    if [ "$SOUND_COUNT" -eq 1 ]; then
        SOUND_FILE="$MATCHING_SOUNDS"
    else
        RANDOM_LINE=$((RANDOM % SOUND_COUNT + 1))
        SOUND_FILE=$(echo "$MATCHING_SOUNDS" | sed -n "${RANDOM_LINE}p")
    fi
fi

debug_log "Selected sound: $SOUND_FILE"

SOUND_PATH="${BASE_PATH}/${SOUND_FILE}"

# Verify sound file exists
if [ ! -f "$SOUND_PATH" ]; then
    debug_log "Sound file not found: $SOUND_PATH, using default"
    SOUND_PATH="${BASE_PATH}/tadUpd03-addon-complete.wav"
fi

debug_log "Final sound path: $SOUND_PATH"
debug_log "File exists: $([ -f "$SOUND_PATH" ] && echo "YES" || echo "NO")"

# Play the sound
if [ -f "$SOUND_PATH" ]; then
    debug_log "Playing sound: $SOUND_PATH"
    afplay "$SOUND_PATH" 2>&1 &
    debug_log "Sound play command executed"
else
    debug_log "ERROR: Sound file still does not exist: $SOUND_PATH"
fi

debug_log "Router execution complete"
exit 0
