#!/bin/bash

# StarCraft Sound Router v3.0
# Direct 14-class semantic mapping with token-efficient Claude API classification

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_MAP_FILE="${SCRIPT_DIR}/starcraft-sounds.json"
LOG_FILE="${SCRIPT_DIR}/router.log"
ENV_FILE="${SCRIPT_DIR}/.env"
DEFAULT_CLASS=5

# Sound directory from JSON config
SOUND_DIR="/Users/user/Music/StarCraft/Starcraft1/Terran/Advisor-Annotated"

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Load environment variables if .env exists
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# Read JSON hook input from stdin
HOOK_INPUT=$(cat)

# Extract transcript path from hook input (supports both camelCase and snake_case)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcriptPath // .transcript_path // empty')

if [ -z "$TRANSCRIPT_PATH" ]; then
    log_message "ERROR: No transcript path in hook input"
    exit 0  # Exit silently
fi

# Get the last assistant message from transcript (JSONL format - one JSON object per line)
ASSISTANT_MESSAGE=$(jq -s '
    [.[] | select(.role == "assistant" or (.message and .message.role == "assistant"))] |
    if length > 0 then
        last |
        .content[-1].text // .message.content[-1].text // empty
    else
        empty
    end
' "$TRANSCRIPT_PATH" 2>/dev/null)

if [ -z "$ASSISTANT_MESSAGE" ]; then
    log_message "ERROR: Could not extract assistant message from transcript"
    exit 0  # Exit silently
fi

# Truncate message for logging (first 100 chars)
MESSAGE_PREVIEW="${ASSISTANT_MESSAGE:0:100}..."
log_message "Processing message: $MESSAGE_PREVIEW"

# Function to play sound for a given class
play_sound_for_class() {
    local class_id="$1"

    # Get sound file for this class
    local sound_file=$(jq -r ".sounds.\"$class_id\".file // empty" "$SOUND_MAP_FILE")

    if [ -z "$sound_file" ]; then
        log_message "WARNING: No sound mapped for class $class_id"
        return 1
    fi

    local full_path="${SOUND_DIR}/${sound_file}"

    if [ ! -f "$full_path" ]; then
        log_message "ERROR: Sound file not found: $full_path"
        return 1
    fi

    # Play the sound in background
    afplay "$full_path" &
    log_message "Playing sound for class $class_id: $sound_file"
    return 0
}

# Function to classify message using Claude API
classify_with_claude() {
    local message="$1"

    # Check if API key is available
    if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
        log_message "WARNING: No ANTHROPIC_API_KEY found, using default class"
        echo "$DEFAULT_CLASS"
        return
    fi

    # Prepare the token-efficient prompt
    local prompt="Classify this AI assistant message into ONE of 14 classes:

1=Need clarification (ambiguous request)
2=Need resources (missing files/access)
3=Need selection (multiple options)
4=Cannot locate (search failed)
5=Routine complete (small task done)
6=Milestone complete (major task done)
7=Discovery complete (found/analyzed)
8=Removal complete (deleted/cleaned)
9=Optimal achievement (exceptional success)
10=Partial completion (mostly done)
11=Problems discovered (found issues)
12=Operation failing (current errors)
13=Critical failure (emergency)
14=Request impossible (cannot do)

Message: ${message:0:500}

Return ONLY: {\"class\": N}"

    # Call Claude API
    local response=$(curl -s -X POST https://api.anthropic.com/v1/messages \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$(jq -n \
            --arg prompt "$prompt" \
            '{
                model: "claude-3-haiku-20240307",
                max_tokens: 20,
                temperature: 0.3,
                messages: [{
                    role: "user",
                    content: $prompt
                }]
            }')" 2>/dev/null)

    # Extract class number from response
    local class_num=$(echo "$response" | jq -r '
        .content[0].text // "" |
        try (fromjson | .class) // empty
    ' 2>/dev/null)

    # Validate class number
    if [[ "$class_num" =~ ^[0-9]+$ ]] && [ "$class_num" -ge 1 ] && [ "$class_num" -le 14 ]; then
        echo "$class_num"
    else
        log_message "WARNING: Invalid classification response, using default"
        echo "$DEFAULT_CLASS"
    fi
}

# Main execution
main() {
    # Classify the message
    CLASS=$(classify_with_claude "$ASSISTANT_MESSAGE")

    # Log the classification
    local class_name=$(jq -r ".sounds.\"$CLASS\".class // \"Unknown\"" "$SOUND_MAP_FILE")
    log_message "Classified as: $CLASS - $class_name"

    # Play the corresponding sound
    play_sound_for_class "$CLASS"
}

# Run main function
main

# Exit successfully
exit 0