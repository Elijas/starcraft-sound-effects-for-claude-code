#!/bin/bash

# StarCraft Sound Router v3.0
# Direct 14-class semantic mapping with token-efficient Claude API classification

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_CONFIG_FILE="${SCRIPT_DIR}/sound-config.json"
USER_CONFIG_FILE="${HOME}/.config/starcraft-sounds.yaml"
LOG_FILE="${SCRIPT_DIR}/router.log"
ENV_FILE="${SCRIPT_DIR}/.env"
DEFAULT_CLASS=5
ENABLE_LOGGING="${ENABLE_LOGGING:-false}"  # Set to true (or export ENABLE_LOGGING=true) to enable logging

# Model self-healing: the classifier pins a Haiku model. Models get retired over
# time, so on a "model not found" error the router discovers the newest Haiku from
# the API and durably caches it (see classify_with_claude / discover_newest_haiku).
DEFAULT_HAIKU_MODEL="${DEFAULT_HAIKU_MODEL:-claude-haiku-4-5-20251001}"  # Baked-in fallback
MODEL_CACHE_FILE="${SCRIPT_DIR}/.haiku-model"  # Durable last-known-good model (gitignored)

# Foreground-session gate: only make sound when a human is actively watching this
# session. Stays silent for background/headless sessions (e.g. `claude -p`) and
# in-process subagents. Override with the STARCRAFT_SOUNDS env var:
#   1/on/true  -> always play        0/off/false -> always silent        unset -> auto
SOUND_SCOPE="${STARCRAFT_SOUNDS:-auto}"

# Source sound path resolver
source "${SCRIPT_DIR}/sound-path-resolver.sh"

# Load environment variables - required
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: Missing .env file. Please copy .env.example to .env and configure it." >&2
    exit 1
fi
export $(grep -v '^#' "$ENV_FILE" | xargs)

# Check required environment variables
if [ -z "${STARCRAFT_ROOT_DIR:-}" ]; then
    echo "ERROR: STARCRAFT_ROOT_DIR not set in .env file" >&2
    exit 1
fi

if [ ! -d "$STARCRAFT_ROOT_DIR" ]; then
    echo "ERROR: StarCraft root directory not found: $STARCRAFT_ROOT_DIR" >&2
    exit 1
fi

if [ ! -f "$SOUND_CONFIG_FILE" ]; then
    echo "ERROR: Sound config file not found: $SOUND_CONFIG_FILE" >&2
    exit 1
fi

# Logging function (only logs if enabled)
log_message() {
    [ "$ENABLE_LOGGING" = true ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    return 0
}

# ─── Foreground-session gate ─────────────────────────────────────────────────
# Return 0 (make sound) only when a human is actively watching this session;
# return 1 to stay silent for background workers, subagents, and explicit opt-outs.
#
# "Attended" is defined via tmux: a session is foreground iff it has >=1 attached
# client (tmux's #{session_attached}). Evaluated LIVE at each Stop, so a detached
# tmux session re-attached to a client (brought to the foreground) starts playing
# with no relaunch, and a foreground session detached into the background goes quiet.
# (CLAUDE_CODE_CHILD_SESSION is NOT usable here — it is always "1" inside any hook
# subprocess. SubagentStop events carry agent_id; the primary Stop does not.)
should_play_sound() {
    # 1. Explicit override always wins
    case "$(printf '%s' "$SOUND_SCOPE" | tr '[:upper:]' '[:lower:]')" in
        1|on|true|yes|enable|enabled)
            return 0 ;;
        0|off|false|no|disable|disabled|silent|mute)
            log_message "Gate: silenced by STARCRAFT_SOUNDS override"
            return 1 ;;
    esac

    # 2. Never fire for subagent completions (defense-in-depth if wired to SubagentStop)
    local event agent_id
    event=$(echo "$HOOK_INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null || true)
    agent_id=$(echo "$HOOK_INPUT" | jq -r '.agent_id // empty' 2>/dev/null || true)
    if [ "$event" = "SubagentStop" ] || [ -n "$agent_id" ]; then
        log_message "Gate: silenced (subagent event: ${event:-agent_id present})"
        return 1
    fi

    # 3. Foreground detection: only an attended (tmux-attached) session makes sound.
    if [ -z "${TMUX:-}" ]; then
        # Not in tmux -> plain interactive terminal you're looking at -> play
        return 0
    fi
    local attached
    if [ -n "${TMUX_PANE:-}" ]; then
        attached=$(tmux display-message -t "$TMUX_PANE" -p '#{session_attached}' 2>/dev/null || true)
    else
        attached=$(tmux display-message -p '#{session_attached}' 2>/dev/null || true)
    fi
    if [ -z "$attached" ]; then
        # Couldn't read tmux state (stale/leaked $TMUX). Bias to silence so a fleet
        # of background workers can't start a chorus; force with STARCRAFT_SOUNDS=1.
        log_message "Gate: silenced (tmux attach state unknown)"
        return 1
    fi
    if [ "$attached" -gt 0 ] 2>/dev/null; then
        return 0
    fi
    log_message "Gate: silenced (session detached / background worker)"
    return 1
}

# Read JSON hook input from stdin
HOOK_INPUT=$(cat)

# Gate as early as possible: bail before any transcript parsing or API call for
# background workers / subagents / explicit opt-outs. Only attended sessions reach
# the heavy work below.
if ! should_play_sound; then
    exit 0
fi

# Extract transcript path from hook input (supports both camelCase and snake_case)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcriptPath // .transcript_path // empty')

if [ -z "$TRANSCRIPT_PATH" ]; then
    log_message "ERROR: No transcript path in hook input"
    exit 0  # Exit silently
fi

# Get the last assistant message from transcript (JSONL format - one JSON object per line)
# Find the last assistant message that HAS text content (skip tool-only messages)
ASSISTANT_MESSAGE=$(jq -s '
    [.[] | select(.role == "assistant" or (.message and .message.role == "assistant"))] |
    map(
        . as $msg |
        ($msg.content // $msg.message.content) |
        map(select(.type == "text")) |
        if length > 0 then {msg: $msg, texts: .} else empty end
    ) |
    if length > 0 then
        last.texts | last.text
    else
        empty
    end
' "$TRANSCRIPT_PATH" 2>/dev/null)

if [ -z "$ASSISTANT_MESSAGE" ]; then
    log_message "ERROR: Could not extract assistant message from transcript"
    exit 0  # Exit silently
fi

# Smart truncate message for logging (first 60 + last 40 chars if too long)
if [ "${#ASSISTANT_MESSAGE}" -le 100 ]; then
    MESSAGE_PREVIEW="$ASSISTANT_MESSAGE"
else
    MESSAGE_PREVIEW="${ASSISTANT_MESSAGE:0:60}[...]${ASSISTANT_MESSAGE: -40}"
fi
log_message "Processing message: $MESSAGE_PREVIEW"

# Function to play sound for a given class
play_sound_for_class() {
    local class_id="$1"

    # Get sound config for this class from centralized config (supports string or object)
    local sound_config=$(jq -c ".semantic_sounds.\"$class_id\" // empty" "$SOUND_CONFIG_FILE")

    if [ -z "$sound_config" ] || [ "$sound_config" = "null" ]; then
        log_message "WARNING: No sound mapped for class $class_id"
        return 1
    fi

    # Parse config (can be string or object with path/exclude)
    local config_type=$(echo "$sound_config" | jq -r 'type')
    local relative_path
    local exclude_json=""

    if [ "$config_type" = "object" ]; then
        relative_path=$(echo "$sound_config" | jq -r '.path // empty')
        exclude_json=$(echo "$sound_config" | jq -c '.exclude // empty')
    else
        relative_path=$(echo "$sound_config" | jq -r '.')
    fi

    if [ -z "$relative_path" ]; then
        log_message "WARNING: No path configured for class $class_id"
        return 1
    fi

    # Resolve the path (supports both files and folders, with optional exclusions)
    local full_path=$(resolve_sound_path "$relative_path" "$exclude_json")

    if [ -z "$full_path" ] || [ ! -f "$full_path" ]; then
        log_message "ERROR: Could not resolve sound path: $relative_path"
        return 1
    fi

    # Play the sound (synchronous - whole main runs in background)
    afplay "$full_path"
    log_message "Playing sound for class $class_id: $full_path"
    return 0
}

# ─── Model self-healing ──────────────────────────────────────────────────────
# Return the model to use: the cached last-known-good (from a previous self-heal)
# or the baked-in default. This is the fast path — no network call.
get_current_model() {
    if [ -f "$MODEL_CACHE_FILE" ]; then
        local cached
        cached=$(tr -d '[:space:]' < "$MODEL_CACHE_FILE" 2>/dev/null || true)
        if [ -n "$cached" ]; then
            echo "$cached"
            return
        fi
    fi
    echo "$DEFAULT_HAIKU_MODEL"
}

# Durably (and atomically) persist the working model for future sessions.
save_model() {
    local model="$1"
    local tmp
    tmp=$(mktemp "${MODEL_CACHE_FILE}.XXXXXX" 2>/dev/null) || return 1
    if printf '%s\n' "$model" > "$tmp"; then
        mv -f "$tmp" "$MODEL_CACHE_FILE"
    else
        rm -f "$tmp"
        return 1
    fi
}

# Ask the API for its model list and echo the newest Haiku id (by created_at).
# Returns non-zero if the list is unavailable or contains no Haiku model.
discover_newest_haiku() {
    local models_json newest
    models_json=$(curl -s https://api.anthropic.com/v1/models \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" 2>/dev/null || true)

    # Filter to Haiku models, sort by created_at (authoritative — names aren't
    # lexically monotonic across generations), take the newest.
    newest=$(echo "$models_json" | jq -r '
        [.data[]? | select((.id // "") | ascii_downcase | contains("haiku"))]
        | sort_by(.created_at) | reverse | .[0].id // empty
    ' 2>/dev/null || true)

    if [ -n "$newest" ] && [ "$newest" != "null" ]; then
        echo "$newest"
        return 0
    fi
    return 1
}

# Single classification API call for a given model. Echoes the raw JSON response.
call_claude_api() {
    local model="$1"
    local prompt="$2"
    curl -s -X POST https://api.anthropic.com/v1/messages \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$(jq -n --arg prompt "$prompt" --arg model "$model" \
            '{
                model: $model,
                max_tokens: 20,
                temperature: 0.3,
                messages: [{ role: "user", content: $prompt }]
            }')" 2>/dev/null
}

# Extract the class integer from an API response. Robust to bare JSON
# ({"class": 9}) and markdown-fenced JSON (```json\n{"class": 9}\n```), which
# newer models emit. Returns non-zero if no class integer can be found.
extract_class() {
    local response="$1"
    local text n
    text=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null || true)
    [ -z "$text" ] && return 1

    # Preferred: match the "class": N field directly, ignoring fences/whitespace
    n=$(echo "$text" | grep -oE '"class"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
    # Fallback: first integer anywhere (the only digits present are the class)
    [ -z "$n" ] && n=$(echo "$text" | grep -oE '[0-9]+' | head -1 || true)

    [ -n "$n" ] && { echo "$n"; return 0; }
    return 1
}

# Function to classify message using Claude API (with model self-healing)
classify_with_claude() {
    local message="$1"

    # Check if API key is available
    if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
        log_message "WARNING: No ANTHROPIC_API_KEY found, using default class"
        echo "$DEFAULT_CLASS"
        return
    fi

    # Smart truncation: capture beginning and end if message is too long
    local truncated_message=""
    local msg_length=${#message}
    local first_chars=1000
    local last_chars=1000
    local max_total=$((first_chars + last_chars))

    if [ "$msg_length" -le "$max_total" ]; then
        # Message is short enough, use it all
        truncated_message="$message"
    else
        # Message is too long, take beginning and end
        truncated_message="${message:0:$first_chars}
[...]
${message: -$last_chars}"
    fi

    # Prepare the crisp classification prompt
    local prompt="Classify this Claude Code assistant response by its semantic outcome.

Classes:
1=Need clarification (ambiguous, need details)
2=Need permissions (missing API key/credentials)
3=Need user choice (multiple valid options)
4=Search failed (couldn't find file/function)
5=Simple edit done (single file, minor change)
6=Feature complete (function/bug fix/refactor)
7=Analysis complete (code explained/files read)
8=Cleanup complete (deleted/removed code)
9=Deployed successfully (git push/tests pass/exploration sealed)
10=Partially done (most complete, some remain)
11=Issues found (warnings/lint errors discovered)
12=Tests failing (build/type/test errors)
13=System broken (can't compile/repo corrupt)
14=Cannot proceed (impossible/out of scope)

<claude_code_response>
$truncated_message
</claude_code_response>

Return only raw JSON, no markdown code fences: {\"class\": N}"

    # Resolve model (cached self-healed value, or baked-in default) and call the API
    local model
    model=$(get_current_model)
    local response
    response=$(call_claude_api "$model" "$prompt" || true)

    # Self-heal: if the pinned model no longer exists (404), discover the newest
    # Haiku, durably cache it for future sessions, and retry once.
    local err_type
    err_type=$(echo "$response" | jq -r '.error.type // empty' 2>/dev/null || true)
    if [ "$err_type" = "not_found_error" ]; then
        log_message "Model '$model' not found (404) — discovering newest Haiku via /v1/models"
        local newest
        if newest=$(discover_newest_haiku); then
            log_message "Self-heal: '$model' -> '$newest' (caching to $MODEL_CACHE_FILE)"
            save_model "$newest" || log_message "WARNING: could not persist model cache"
            model="$newest"
            response=$(call_claude_api "$model" "$prompt" || true)
        else
            log_message "WARNING: Self-heal failed (no Haiku model discoverable), using default class"
            echo "$DEFAULT_CLASS"
            return
        fi
    fi

    # Extract and validate class number
    local class_num
    class_num=$(extract_class "$response" || true)
    if [[ "$class_num" =~ ^[0-9]+$ ]] && [ "$class_num" -ge 1 ] && [ "$class_num" -le 14 ]; then
        echo "$class_num"
    else
        log_message "WARNING: Invalid classification response, using default"
        echo "$DEFAULT_CLASS"
    fi
}

# Main execution
main() {
    # Check user config for completion mode
    if [ -f "$USER_CONFIG_FILE" ]; then
        local mode=$(yq -r '.completion.mode // "default"' "$USER_CONFIG_FILE" 2>/dev/null || echo "default")
        local sound=$(yq -r '.completion.sound // ""' "$USER_CONFIG_FILE" 2>/dev/null || echo "")

        case "$mode" in
            silent)
                log_message "Completion mode: silent (skipping)"
                return 0
                ;;
            single)
                if [ -n "$sound" ] && [ -f "$sound" ]; then
                    afplay "$sound"
                    log_message "Completion mode: single sound: $sound"
                else
                    log_message "WARNING: Single mode but sound file not found: $sound"
                fi
                return 0
                ;;
            # default: fall through to normal classification
        esac
    fi

    # Classify the message
    CLASS=$(classify_with_claude "$ASSISTANT_MESSAGE")

    # Log the classification with simple names
    case "$CLASS" in
        1) class_name="Need clarification" ;;
        2) class_name="Need permissions" ;;
        3) class_name="Need user choice" ;;
        4) class_name="Search failed" ;;
        5) class_name="Simple edit done" ;;
        6) class_name="Feature complete" ;;
        7) class_name="Analysis complete" ;;
        8) class_name="Cleanup complete" ;;
        9) class_name="Deployed successfully" ;;
        10) class_name="Partially done" ;;
        11) class_name="Issues found" ;;
        12) class_name="Tests failing" ;;
        13) class_name="System broken" ;;
        14) class_name="Cannot proceed" ;;
        *) class_name="Unknown" ;;
    esac
    log_message "Classified as: $CLASS - $class_name"

    # Play the corresponding sound
    play_sound_for_class "$CLASS"
}

# Run main function in background (non-blocking)
# Fork once here, everything inside main runs synchronously
main &
disown

# Exit immediately - don't wait for background process
exit 0