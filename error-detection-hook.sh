#!/bin/bash

# Error Detection Hook for Claude Code
# Algorithmic (NO AI) error detection from tool outputs
# Plays sound when errors are detected in tool responses

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_CONFIG_FILE="${SCRIPT_DIR}/sound-config.json"
ENV_FILE="${SCRIPT_DIR}/.env"
ENABLE_LOGGING=true  # Set to true for debugging
LOG_FILE="${HOME}/.claude/error-detection.log"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# Check required configuration
if [ -z "${STARCRAFT_ROOT_DIR:-}" ]; then
    echo "ERROR: STARCRAFT_ROOT_DIR not set in .env file" >&2
    exit 1
fi

if [ ! -f "$SOUND_CONFIG_FILE" ]; then
    echo "ERROR: Sound config file not found: $SOUND_CONFIG_FILE" >&2
    exit 1
fi

# Get error sound path from centralized config
ERROR_SOUND_RELATIVE=$(jq -r '.error_sound // empty' "$SOUND_CONFIG_FILE")
if [ -z "$ERROR_SOUND_RELATIVE" ]; then
    echo "ERROR: error_sound not configured in $SOUND_CONFIG_FILE" >&2
    exit 1
fi

# Construct full path
SOUND_FILE="${STARCRAFT_ROOT_DIR}/${ERROR_SOUND_RELATIVE}"

# Logging function
log_message() {
    if [ "$ENABLE_LOGGING" = true ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    fi
}

# Read JSON hook input from stdin
HOOK_INPUT=$(cat)

# Extract key fields
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // "unknown"')
TOOL_RESPONSE=$(echo "$HOOK_INPUT" | jq -r '.tool_response // {}')

# Extract error indicators from tool_response
EXIT_CODE=$(echo "$TOOL_RESPONSE" | jq -r '.exitCode // null')
STDERR=$(echo "$TOOL_RESPONSE" | jq -r '.stderr // ""')
STDOUT=$(echo "$TOOL_RESPONSE" | jq -r '.stdout // ""')
ERROR_FIELD=$(echo "$TOOL_RESPONSE" | jq -r '.error // ""')
SUCCESS=$(echo "$TOOL_RESPONSE" | jq -r '.success // null')

log_message "=== Hook triggered for tool: $TOOL_NAME ==="

# Initialize error detection flag
ERROR_DETECTED=false

# Pattern 1: Non-zero exit code
if [[ "$EXIT_CODE" != "null" ]] && [[ "$EXIT_CODE" =~ ^[1-9][0-9]*$ ]]; then
    log_message "ERROR: Non-zero exit code detected: $EXIT_CODE"
    ERROR_DETECTED=true
fi

# Pattern 2: stderr contains error indicators
if [[ -n "$STDERR" ]] && [[ "$STDERR" != "null" ]]; then
    # Check for common error patterns in stderr (case-insensitive)
    if echo "$STDERR" | grep -qiE '(traceback|error:|exception|failed|fatal|critical|syntax error|cannot find|permission denied|no such file|command not found|connection refused|timeout)'; then
        log_message "ERROR: Error pattern detected in stderr"
        ERROR_DETECTED=true
    fi
fi

# Pattern 3: Explicit error field populated
if [[ -n "$ERROR_FIELD" ]] && [[ "$ERROR_FIELD" != "null" ]] && [[ "$ERROR_FIELD" != "" ]]; then
    log_message "ERROR: Error field populated: $ERROR_FIELD"
    ERROR_DETECTED=true
fi

# Pattern 4: success=false
if [[ "$SUCCESS" == "false" ]]; then
    log_message "ERROR: Tool reported success=false"
    ERROR_DETECTED=true
fi

# Pattern 5: stdout contains Python/JS error patterns
if [[ -n "$STDOUT" ]] && [[ "$STDOUT" != "null" ]]; then
    # Check for Python exceptions
    if echo "$STDOUT" | grep -qE '(Traceback \(most recent call last\)|SyntaxError|ValueError|TypeError|KeyError|IndexError|AttributeError|ImportError|RuntimeError|NameError)'; then
        log_message "ERROR: Python error detected in stdout"
        ERROR_DETECTED=true
    fi

    # Check for JavaScript errors
    if echo "$STDOUT" | grep -qE '(Error:|TypeError:|ReferenceError:|SyntaxError:|RangeError:)'; then
        log_message "ERROR: JavaScript error detected in stdout"
        ERROR_DETECTED=true
    fi
fi

# If error detected, play sound
if [ "$ERROR_DETECTED" = true ]; then
    log_message "Playing error sound: $SOUND_FILE"

    # Verify sound file exists
    if [ -f "$SOUND_FILE" ]; then
        # Play sound in background (don't wait for completion)
        afplay "$SOUND_FILE" &
        log_message "Sound playback initiated"
    else
        log_message "WARNING: Sound file not found: $SOUND_FILE"
    fi
else
    log_message "No errors detected"
fi

# Exit successfully (don't block Claude's workflow)
exit 0
