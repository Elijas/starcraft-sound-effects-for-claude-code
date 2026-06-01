#!/bin/bash

# Error Detection Hook for Claude Code
# Algorithmic (NO AI) error detection from tool outputs
# Plays sound when errors are detected in tool responses
#
# NOTE: Due to a Claude Code bug, PostToolUse hooks are NOT called for
# failed Bash commands (non-zero exit codes). This hook only works for
# successful tool calls. See: https://github.com/anthropics/claude-code/issues
#
# PERF: error detection runs FIRST and the hook exits immediately when no error is found
# (the common case), so the config-file reads (jq/yq) and sound resolution only happen on
# the rare error path. This keeps per-tool-call process spawns near zero — an earlier
# version read configs on every single tool call, which (multiplied across many concurrent
# sessions) produced a process fork-storm that froze the machine.

set -uo pipefail

# Configuration paths (string assignment only — no subprocess)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_CONFIG_FILE="${SCRIPT_DIR}/sound-config.json"
USER_CONFIG_FILE="${HOME}/.config/starcraft-sounds.yaml"
ENV_FILE="${SCRIPT_DIR}/.env"
ENABLE_LOGGING=false  # Set to true for debugging
LOG_FILE="${HOME}/.claude/error-detection.log"

# Logging function
log_message() {
    if [ "$ENABLE_LOGGING" = true ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    fi
}

# Read JSON hook input and extract all fields in ONE jq pass via @sh + eval.
# @sh shell-quotes each value, so multiline stdout/stderr survive intact and eval is safe.
HOOK_INPUT=$(cat)
TOOL_NAME="unknown"; EXIT_CODE="null"; STDERR=""; STDOUT=""; ERROR_FIELD=""; SUCCESS="null"
eval "$(printf '%s' "$HOOK_INPUT" | jq -r '
    ( (.tool_response // {}) | if type == "object" then . else {} end ) as $r
    | "TOOL_NAME=\(.tool_name // "unknown" | @sh)",
      "EXIT_CODE=\(($r.exitCode // "null") | tostring | @sh)",
      "STDERR=\($r.stderr // "" | @sh)",
      "STDOUT=\($r.stdout // "" | @sh)",
      "ERROR_FIELD=\($r.error // "" | @sh)",
      "SUCCESS=\(($r.success // "null") | tostring | @sh)"
  ' 2>/dev/null)"

log_message "=== Hook triggered for tool: $TOOL_NAME ==="

# Initialize error detection flag and reasons array
ERROR_DETECTED=false
ERROR_REASONS=()

# Pattern 1: Non-zero exit code
if [[ "$EXIT_CODE" != "null" ]] && [[ "$EXIT_CODE" =~ ^[1-9][0-9]*$ ]]; then
    log_message "ERROR: Non-zero exit code detected: $EXIT_CODE"
    ERROR_DETECTED=true
    ERROR_REASONS+=("exit $EXIT_CODE")
fi

# Pattern 2: stderr contains error indicators
if [[ -n "$STDERR" ]] && [[ "$STDERR" != "null" ]]; then
    # Check for common error patterns in stderr (case-insensitive)
    STDERR_MATCH=$(echo "$STDERR" | grep -oiE '(traceback|error|exception|failed|fatal|critical|syntax error|cannot find|permission denied|no such file|command not found|connection refused|timeout)' | head -1 | tr '[:upper:]' '[:lower:]')
    if [[ -n "$STDERR_MATCH" ]]; then
        log_message "ERROR: Error pattern detected in stderr: $STDERR_MATCH"
        ERROR_DETECTED=true
        ERROR_REASONS+=("$STDERR_MATCH")
    fi
fi

# Pattern 3: Explicit error field populated
if [[ -n "$ERROR_FIELD" ]] && [[ "$ERROR_FIELD" != "null" ]] && [[ "$ERROR_FIELD" != "" ]]; then
    log_message "ERROR: Error field populated: $ERROR_FIELD"
    ERROR_DETECTED=true
    # Extract first meaningful word/phrase from error field
    ERROR_WORD=$(echo "$ERROR_FIELD" | grep -oE '^[A-Za-z_]+' | head -1)
    if [[ -n "$ERROR_WORD" ]]; then
        ERROR_REASONS+=("$ERROR_WORD")
    else
        ERROR_REASONS+=("error")
    fi
fi

# Pattern 4: success=false
if [[ "$SUCCESS" == "false" ]]; then
    log_message "ERROR: Tool reported success=false"
    ERROR_DETECTED=true
    ERROR_REASONS+=("failed")
fi

# Pattern 5: stdout contains Python/JS error patterns (Bash only)
if [[ "$TOOL_NAME" == "Bash" ]] && [[ -n "$STDOUT" ]] && [[ "$STDOUT" != "null" ]]; then
    # Check for Python exceptions
    PY_MATCH=$(echo "$STDOUT" | grep -oE '(Traceback|SyntaxError|ValueError|TypeError|KeyError|IndexError|AttributeError|ImportError|RuntimeError|NameError)' | head -1)
    if [[ -n "$PY_MATCH" ]]; then
        log_message "ERROR: Python error detected in stdout: $PY_MATCH"
        ERROR_DETECTED=true
        ERROR_REASONS+=("$PY_MATCH")
    fi

    # Check for JavaScript errors
    JS_MATCH=$(echo "$STDOUT" | grep -oE '(TypeError|ReferenceError|SyntaxError|RangeError)' | head -1)
    if [[ -n "$JS_MATCH" ]]; then
        log_message "ERROR: JavaScript error detected in stdout: $JS_MATCH"
        ERROR_DETECTED=true
        ERROR_REASONS+=("$JS_MATCH")
    fi
fi

# Common case: no error detected -> exit now, before any config/sound work.
if [ "$ERROR_DETECTED" != true ]; then
    log_message "No errors detected"
    exit 0
fi

# ===========================================================================
# Error detected (rare path): load config, resolve the sound, and play it.
# ===========================================================================

# Source sound path resolver
source "${SCRIPT_DIR}/sound-path-resolver.sh"

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

# Get error sound config from centralized config (supports string or object)
ERROR_SOUND_CONFIG=$(jq -r '.error_sound // empty' "$SOUND_CONFIG_FILE")
if [ -z "$ERROR_SOUND_CONFIG" ]; then
    echo "ERROR: error_sound not configured in $SOUND_CONFIG_FILE" >&2
    exit 1
fi

# Parse config (can be string or object with path/exclude)
ERROR_SOUND_TYPE=$(echo "$ERROR_SOUND_CONFIG" | jq -r 'type')
if [ "$ERROR_SOUND_TYPE" = "object" ]; then
    ERROR_SOUND_RELATIVE=$(echo "$ERROR_SOUND_CONFIG" | jq -r '.path // empty')
    ERROR_SOUND_EXCLUDE=$(echo "$ERROR_SOUND_CONFIG" | jq -c '.exclude // empty')
else
    ERROR_SOUND_RELATIVE="$ERROR_SOUND_CONFIG"
    ERROR_SOUND_EXCLUDE=""
fi

if [ -z "$ERROR_SOUND_RELATIVE" ]; then
    echo "ERROR: error_sound path not configured in $SOUND_CONFIG_FILE" >&2
    exit 1
fi

# Check user config for error mode
ERROR_MODE="default"
ERROR_SOUND_OVERRIDE=""
if [ -f "$USER_CONFIG_FILE" ]; then
    ERROR_MODE=$(yq -r '.error.mode // "default"' "$USER_CONFIG_FILE" 2>/dev/null || echo "default")
    ERROR_SOUND_OVERRIDE=$(yq -r '.error.sound // ""' "$USER_CONFIG_FILE" 2>/dev/null || echo "")
fi

# Handle silent mode - exit early
if [ "$ERROR_MODE" = "silent" ]; then
    exit 0
fi

# Resolve sound file based on mode
if [ "$ERROR_MODE" = "single" ] && [ -n "$ERROR_SOUND_OVERRIDE" ]; then
    SOUND_FILE="$ERROR_SOUND_OVERRIDE"
else
    # Default mode: resolve from sound-config.json
    SOUND_FILE=$(resolve_sound_path "$ERROR_SOUND_RELATIVE" "$ERROR_SOUND_EXCLUDE")
fi

if [ -z "$SOUND_FILE" ]; then
    echo "ERROR: Could not resolve error sound path: $ERROR_SOUND_RELATIVE" >&2
    exit 1
fi

log_message "Playing error sound: $SOUND_FILE"

# Verify sound file exists
if [ -f "$SOUND_FILE" ]; then
    # Play sound in background (fully detached from hook process)
    nohup afplay "$SOUND_FILE" >/dev/null 2>&1 &
    disown
    log_message "Sound playback initiated"
else
    log_message "WARNING: Sound file not found: $SOUND_FILE"
fi

# Speak error reasons using macOS say (deduplicated)
if [ ${#ERROR_REASONS[@]} -gt 0 ]; then
    # Deduplicate reasons while preserving order
    UNIQUE_REASONS=()
    for reason in "${ERROR_REASONS[@]}"; do
        # Check if already in array (handle empty array case)
        FOUND=false
        for existing in "${UNIQUE_REASONS[@]+"${UNIQUE_REASONS[@]}"}"; do
            if [[ "$existing" == "$reason" ]]; then
                FOUND=true
                break
            fi
        done
        if [[ "$FOUND" == "false" ]]; then
            UNIQUE_REASONS+=("$reason")
        fi
    done
    SAY_TEXT=$(IFS=', '; echo "${UNIQUE_REASONS[*]}")
    log_message "Speaking: $SAY_TEXT"
    # Delay so sound plays before speech (fully detached)
    nohup bash -c "sleep 2 && say '$SAY_TEXT'" >/dev/null 2>&1 &
    disown
fi

# Exit successfully (don't block Claude's workflow)
exit 0
