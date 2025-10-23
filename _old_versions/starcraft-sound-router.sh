#!/bin/bash

# StarCraft Sound Router
# Routes Claude Code responses to contextually appropriate StarCraft Terran Advisor sounds

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_JSON="${SCRIPT_DIR}/starcraft-sounds.json"
TEMP_DIR="${TMPDIR:-/tmp}/starcraft-router"
mkdir -p "$TEMP_DIR"

# Read hook input from stdin (JSON format)
HOOK_INPUT=$(cat)

# Parse JSON input to extract transcript_path and stop_hook_active
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")

# Expand tilde in transcript path if present
if [[ "$TRANSCRIPT_PATH" == "~"* ]]; then
    TRANSCRIPT_PATH="${HOME}${TRANSCRIPT_PATH:1}"
fi

# Prevent infinite loops
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# Debug mode (set STARCRAFT_DEBUG=1 to enable)
DEBUG="${STARCRAFT_DEBUG:-0}"
debug_log() {
    if [ "$DEBUG" = "1" ]; then
        echo "[DEBUG] $*" >&2
    fi
}

debug_log "Starting StarCraft sound router"
debug_log "Transcript path: $TRANSCRIPT_PATH"

# Extract Claude's latest response from transcript
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    debug_log "No valid transcript path provided, exiting"
    exit 0
fi

# Parse the transcript to get Claude's last message
# The transcript is a JSON array of messages
LAST_ASSISTANT_MESSAGE=$(jq -r '[.[] | select(.role == "assistant")] | last | .content | if type == "array" then [.[] | select(.type == "text")] | last | .text else . end' "$TRANSCRIPT_PATH" 2>/dev/null || echo "")

if [ -z "$LAST_ASSISTANT_MESSAGE" ] || [ "$LAST_ASSISTANT_MESSAGE" = "null" ]; then
    debug_log "No assistant message found in transcript"
    exit 0
fi

debug_log "Last assistant message length: ${#LAST_ASSISTANT_MESSAGE}"

# Create a prompt for Claude (Haiku) to analyze the response and pick a sound
ANALYSIS_PROMPT="You are a sound effect router for StarCraft Terran Advisor sounds. Analyze the following Claude Code response and determine the most contextually appropriate sound to play.

Available sounds and their contexts:
$(cat "$SOUNDS_JSON" | jq -r '.sounds[] | "- \(.file): \(.description) (contexts: \(.contexts | join(", ")))"')

Claude's response:
\`\`\`
${LAST_ASSISTANT_MESSAGE:0:2000}
\`\`\`

Based on the response content, tone, and context (success, error, question, information, etc.), select the SINGLE most appropriate sound file.

Consider:
- If there are errors, failures, or problems → use error sounds
- If there are successes, completions, or confirmations → use update/success sounds
- If asking questions or awaiting input → use waiting/standing by sounds
- If providing information or searching → use receiving/coordinates sounds
- Match the emotional tone and severity

Respond with ONLY a JSON object in this exact format:
{
  \"sound_file\": \"tadUpd01.wav\",
  \"reasoning\": \"Brief explanation of why this sound fits\"
}

Do not include any other text, markdown formatting, or code blocks. Just the raw JSON object."

# Write prompt to temp file for debugging
PROMPT_FILE="$TEMP_DIR/last_prompt.txt"
echo "$ANALYSIS_PROMPT" > "$PROMPT_FILE"
debug_log "Prompt written to: $PROMPT_FILE"

# Invoke claude-code with Haiku model
# Using --no-status to get clean output and --model to specify Haiku
debug_log "Invoking claude-code with Haiku model..."

CLAUDE_OUTPUT=$(echo "$ANALYSIS_PROMPT" | claude-code --model haiku --no-status 2>/dev/null || echo '{"sound_file": "tadUpd00.wav", "reasoning": "default"}')

debug_log "Claude output: $CLAUDE_OUTPUT"

# Extract sound file from response
# Try to parse as JSON first, fallback to default if it fails
SOUND_FILE=$(echo "$CLAUDE_OUTPUT" | jq -r '.sound_file' 2>/dev/null || echo "tadUpd00.wav")

# If we still couldn't get a valid sound file, extract any .wav filename from the output
if [ -z "$SOUND_FILE" ] || [ "$SOUND_FILE" = "null" ]; then
    SOUND_FILE=$(echo "$CLAUDE_OUTPUT" | grep -o 'tad[^"]*\.wav' | head -1 || echo "tadUpd00.wav")
fi

debug_log "Selected sound: $SOUND_FILE"

# Get full path from sounds.json
BASE_PATH=$(jq -r '.base_path' "$SOUNDS_JSON")
SOUND_PATH="${BASE_PATH}/${SOUND_FILE}"

# Verify sound file exists
if [ ! -f "$SOUND_PATH" ]; then
    debug_log "Sound file not found: $SOUND_PATH, using default"
    SOUND_PATH="${BASE_PATH}/tadUpd00.wav"
fi

# Play the sound (macOS uses afplay)
debug_log "Playing sound: $SOUND_PATH"
afplay "$SOUND_PATH" &

# Output JSON result (for hook response)
jq -n --arg sound "$SOUND_FILE" --arg path "$SOUND_PATH" '{
    "sound_file": $sound,
    "sound_path": $path,
    "status": "played"
}'

exit 0
