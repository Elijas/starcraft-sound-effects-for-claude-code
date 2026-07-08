#!/bin/bash

# StarCraft authorization notification hook
# Plays the vespene-gas sound for permission prompts and plan-approval dialogs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_CONFIG_FILE="${SCRIPT_DIR}/sound-config.json"
LOG_FILE="${SCRIPT_DIR}/router.log"
ENV_FILE="${SCRIPT_DIR}/.env"
STATE_DIR="${STARCRAFT_SOUNDS_STATE_DIR:-/tmp/starcraft-sounds-state}"
ENABLE_LOGGING="${ENABLE_LOGGING:-false}"
SOUND_SCOPE="${STARCRAFT_SOUNDS:-auto}"
AUTH_DEBOUNCE_REQUIRED=false

source "${SCRIPT_DIR}/sound-path-resolver.sh"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: Missing .env file. Please copy .env.example to .env and configure it." >&2
    exit 1
fi
export $(grep -v '^#' "$ENV_FILE" | xargs)

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

log_message() {
    [ "$ENABLE_LOGGING" = true ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    return 0
}

HOOK_INPUT=$(cat)

# Notification matcher support can vary by Claude Code version; the in-script
# type check below is the defense-in-depth safety net if matchers are ignored.
# FAIL-CLOSED: an event only plays if it is explicitly a permission prompt (or a
# plan-approval PreToolUse). A Notification with no recognizable permission signal
# stays silent — a missed permission sound is cheaper than a false alarm that
# corrupts what "gas" means. Payloads are logged for forensics when logging is on.
is_authorization_event() {
    local event notification_type tool_name message
    event=$(echo "$HOOK_INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null || true)
    notification_type=$(echo "$HOOK_INPUT" | jq -r '.notification_type // .type // empty' 2>/dev/null || true)
    tool_name=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
    message=$(echo "$HOOK_INPUT" | jq -r '.message // empty' 2>/dev/null || true)

    if [ "$event" = "PreToolUse" ] && [ "$tool_name" = "ExitPlanMode" ]; then
        return 0
    fi

    if [ "$event" = "Notification" ]; then
        log_message "Notification payload: $(echo "$HOOK_INPUT" | tr -d '\n' | head -c 400)"
        # Explicit type field wins in either direction
        if [ "$notification_type" = "permission_prompt" ]; then
            return 0
        fi
        if [ -n "$notification_type" ]; then
            return 1
        fi
        # No type field: accept only if the human-readable message clearly says
        # a permission is being requested; otherwise stay silent (fail-closed).
        case "$message" in
            *"permission"*|*"Permission"*|*"needs your approval"*)
                return 0 ;;
        esac
        log_message "Notification without permission signal — staying silent (fail-closed)"
        return 1
    fi

    return 1
}

should_play_authorization_sound() {
    local force_play=false
    case "$(printf '%s' "$SOUND_SCOPE" | tr '[:upper:]' '[:lower:]')" in
        1|on|true|yes|enable|enabled)
            force_play=true ;;
        0|off|false|no|disable|disabled|silent|mute)
            log_message "Authorization gate: silenced by STARCRAFT_SOUNDS override"
            return 1 ;;
    esac

    if [ -z "${TMUX:-}" ]; then
        AUTH_DEBOUNCE_REQUIRED=false
        return 0
    fi

    local attached
    if [ -n "${TMUX_PANE:-}" ]; then
        attached=$(tmux display-message -t "$TMUX_PANE" -p '#{session_attached}' 2>/dev/null || true)
    else
        attached=$(tmux display-message -p '#{session_attached}' 2>/dev/null || true)
    fi

    if [ -n "$attached" ] && [ "$attached" -gt 0 ] 2>/dev/null; then
        AUTH_DEBOUNCE_REQUIRED=false
        return 0
    fi

    AUTH_DEBOUNCE_REQUIRED=true
    if [ "$force_play" = true ]; then
        return 0
    fi

    local clients
    clients=$(tmux list-clients 2>/dev/null || true)
    if [ -n "$clients" ]; then
        return 0
    fi

    log_message "Authorization gate: silenced (tmux detached and no clients present)"
    return 1
}

debounce_allows_sound() {
    if [ "$AUTH_DEBOUNCE_REQUIRED" != true ]; then
        return 0
    fi

    local session_id marker now mtime age
    session_id=$(echo "$HOOK_INPUT" | jq -r '.session_id // .sessionId // empty' 2>/dev/null || true)
    if [ -n "$session_id" ]; then
        marker="${STATE_DIR}/auth-debounce-${session_id}"
    else
        marker="${STATE_DIR}/auth-debounce-global"
    fi

    mkdir -p "$STATE_DIR"
    if [ -d "$marker" ]; then
        now=$(date +%s)
        mtime=$(stat -f %m "$marker" 2>/dev/null || stat -c %Y "$marker" 2>/dev/null || echo 0)
        age=$((now - mtime))
        if [ "$age" -lt 600 ]; then
            log_message "Authorization debounce: suppressed prompt within TTL (${age}s)"
            return 1
        fi
        rmdir "$marker" 2>/dev/null || true
    fi

    if mkdir "$marker" 2>/dev/null; then
        return 0
    fi

    log_message "Authorization debounce: marker already created by another hook"
    return 1
}

play_authorization_sound() {
    local sound_config relative_path full_path
    sound_config=$(jq -r '.authorization_sound // empty' "$SOUND_CONFIG_FILE")
    if [ -z "$sound_config" ] || [ "$sound_config" = "null" ]; then
        log_message "WARNING: No authorization_sound configured"
        return 0
    fi

    relative_path="$sound_config"
    full_path=$(resolve_sound_path "$relative_path" "")
    if [ -z "$full_path" ] || [ ! -f "$full_path" ]; then
        log_message "ERROR: Could not resolve authorization sound path: $relative_path"
        return 0
    fi

    afplay "$full_path" >/dev/null 2>&1 &
    local afplay_pid=$!
    disown "$afplay_pid" 2>/dev/null || true
    log_message "Playing authorization sound: $full_path"
}

if ! is_authorization_event; then
    exit 0
fi

if ! should_play_authorization_sound; then
    exit 0
fi

if ! debounce_allows_sound; then
    exit 0
fi

play_authorization_sound
exit 0
