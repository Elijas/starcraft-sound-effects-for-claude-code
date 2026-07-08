#!/bin/bash
# Offline v4 hook verification: no API calls and no real audio.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_HOME="${HOME}"
REAL_SETTINGS="${REAL_HOME}/.claude/settings.json"
WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/starcraft-hooks-offline.XXXXXX")
REPO_UNDER_TEST="${WORKDIR}/repo"
SOUND_ROOT="${WORKDIR}/sounds"
SHIM_DIR="${WORKDIR}/bin"
STATE_DIR="${WORKDIR}/state"
TEST_HOME="${WORKDIR}/home"
AFPLAY_LOG="${WORKDIR}/afplay.log"
CURL_LOG="${WORKDIR}/curl.log"
STDERR_LOG="${WORKDIR}/stderr.log"
FAIL_COUNT=0

cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

line_count() {
    if [ -f "$1" ]; then
        wc -l < "$1" | tr -d '[:space:]'
    else
        echo 0
    fi
}

wait_for_lines() {
    local file="$1"
    local expected="$2"
    local deadline=$((SECONDS + 5))
    while [ "$SECONDS" -lt "$deadline" ]; do
        if [ "$(line_count "$file")" -ge "$expected" ]; then
            return 0
        fi
        sleep 0.1
    done
    return 1
}

reset_logs() {
    : > "$AFPLAY_LOG"
    : > "$CURL_LOG"
    : > "$STDERR_LOG"
}

make_sound_file() {
    local relative_path="$1"
    mkdir -p "$(dirname "${SOUND_ROOT}/${relative_path}")"
    : > "${SOUND_ROOT}/${relative_path}"
}

write_transcript() {
    local path="$1"
    local text="$2"
    local tokens="$3"
    jq -cn --arg text "$text" --argjson tokens "$tokens" \
        '{message:{role:"assistant",content:[{type:"text",text:$text}],usage:{input_tokens:$tokens}}}' > "$path"
}

stop_input() {
    local transcript="$1"
    local session_id="$2"
    jq -cn --arg transcript "$transcript" --arg session_id "$session_id" \
        '{hook_event_name:"Stop",session_id:$session_id,transcript_path:$transcript}'
}

run_hook() {
    local script="$1"
    local input="$2"
    local stdout_file="$3"
    shift 3
    printf '%s' "$input" | env \
        HOME="$TEST_HOME" \
        PATH="${SHIM_DIR}:$PATH" \
        STARCRAFT_SOUNDS=1 \
        ENABLE_LOGGING=true \
        STARCRAFT_SOUNDS_STATE_DIR="$STATE_DIR" \
        FAKE_AFPLAY_LOG="$AFPLAY_LOG" \
        FAKE_CURL_LOG="$CURL_LOG" \
        "$@" \
        "$script" > "$stdout_file" 2>> "$STDERR_LOG"
}

setup_fixture_repo() {
    mkdir -p "$REPO_UNDER_TEST" "$SOUND_ROOT" "$SHIM_DIR" "$STATE_DIR" "$TEST_HOME"
    cp "$SCRIPT_DIR/starcraft-sound-router.sh" "$REPO_UNDER_TEST/"
    cp "$SCRIPT_DIR/notification-hook.sh" "$REPO_UNDER_TEST/"
    cp "$SCRIPT_DIR/sound-config.json" "$REPO_UNDER_TEST/"
    cp "$SCRIPT_DIR/sound-path-resolver.sh" "$REPO_UNDER_TEST/"
    cp "$SCRIPT_DIR/test-api-classification.sh" "$REPO_UNDER_TEST/"
    chmod +x "$REPO_UNDER_TEST/starcraft-sound-router.sh" "$REPO_UNDER_TEST/notification-hook.sh"

    cat > "$REPO_UNDER_TEST/.env" <<EOF_ENV
ANTHROPIC_API_KEY=fake-key
STARCRAFT_ROOT_DIR=$SOUND_ROOT
EOF_ENV

    make_sound_file "Starcraft1/Terran/Advisor-Annotated/tadUpd02-research-complete.wav"
    make_sound_file "Starcraft1/Terran/Advisor-Annotated/tadErr02-additional-supply-depots-required.wav"
    make_sound_file "Starcraft1/Terran/Advisor-Annotated/tadErr01-insufficient-vespene-gas.wav"

    cat > "$SHIM_DIR/afplay" <<'EOF_AFPLAY'
#!/bin/bash
printf '%s\n' "$1" >> "${FAKE_AFPLAY_LOG:?}"
exit 0
EOF_AFPLAY
    chmod +x "$SHIM_DIR/afplay"

    cat > "$SHIM_DIR/curl" <<'EOF_CURL'
#!/bin/bash
printf '%s\n' "$*" >> "${FAKE_CURL_LOG:?}"
case "${FAKE_CURL_MODE:-ok}" in
    error)
        printf '%s' '{"error":{"type":"api_error","message":"offline forced error"}}'
        ;;
    models)
        printf '%s' '{"data":[{"id":"claude-haiku-test","created_at":"2026-01-01T00:00:00Z"}]}'
        ;;
    *)
        printf '%s' '{"content":[{"text":"{\"class\": 7}"}]}'
        ;;
esac
EOF_CURL
    chmod +x "$SHIM_DIR/curl"

    cat > "$SHIM_DIR/tmux" <<'EOF_TMUX'
#!/bin/bash
case "$1" in
    display-message)
        printf '%s\n' "${FAKE_TMUX_ATTACHED:-0}"
        ;;
    list-clients)
        if [ -n "${FAKE_TMUX_CLIENTS:-}" ]; then
            printf '%s\n' "$FAKE_TMUX_CLIENTS"
            exit 0
        fi
        exit 1
        ;;
    *)
        exit 1
        ;;
esac
EOF_TMUX
    chmod +x "$SHIM_DIR/tmux"
}

test_static_validation() {
    local ok=true
    while IFS= read -r script; do
        if ! bash -n "$script"; then
            ok=false
        fi
    done < <(find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" -type f | sort)

    if ! jq empty "$SCRIPT_DIR/sound-config.json" "$REAL_SETTINGS"; then
        ok=false
    fi

    if [ "$ok" = true ]; then
        pass "bash -n on shell scripts and jq validation"
    else
        fail "bash -n on shell scripts and jq validation"
    fi
}

test_router_classification() {
    reset_logs
    local transcript="${WORKDIR}/stop.jsonl"
    local stdout_file="${WORKDIR}/router-stop.out"
    local class7="${SOUND_ROOT}/Starcraft1/Terran/Advisor-Annotated/tadUpd02-research-complete.wav"
    write_transcript "$transcript" "Here is the analysis you asked for." 100

    run_hook "$REPO_UNDER_TEST/starcraft-sound-router.sh" "$(stop_input "$transcript" "stop-class7")" "$stdout_file"

    if wait_for_lines "$CURL_LOG" 1 && wait_for_lines "$AFPLAY_LOG" 1 &&
        [ "$(line_count "$AFPLAY_LOG")" -eq 1 ] &&
        grep -Fxq "$class7" "$AFPLAY_LOG"; then
        pass "router classifies via fake curl and plays class-7 sound"
    else
        fail "router classifies via fake curl and plays class-7 sound"
    fi
}

test_router_context_latch() {
    reset_logs
    local transcript="${WORKDIR}/context.jsonl"
    local stdout_file="${WORKDIR}/router-context.out"
    local depots="${SOUND_ROOT}/Starcraft1/Terran/Advisor-Annotated/tadErr02-additional-supply-depots-required.wav"
    local class7="${SOUND_ROOT}/Starcraft1/Terran/Advisor-Annotated/tadUpd02-research-complete.wav"
    write_transcript "$transcript" "The implementation is complete." 850000

    run_hook "$REPO_UNDER_TEST/starcraft-sound-router.sh" "$(stop_input "$transcript" "ctx-session")" "$stdout_file"

    local first_ok=false
    if wait_for_lines "$AFPLAY_LOG" 2 && wait_for_lines "$CURL_LOG" 1 &&
        [ "$(sed -n '1p' "$AFPLAY_LOG")" = "$depots" ] &&
        [ "$(sed -n '2p' "$AFPLAY_LOG")" = "$class7" ] &&
        [ -d "${STATE_DIR}/context-latch-ctx-session" ]; then
        first_ok=true
    fi

    reset_logs
    run_hook "$REPO_UNDER_TEST/starcraft-sound-router.sh" "$(stop_input "$transcript" "ctx-session")" "$stdout_file"

    local second_ok=false
    if wait_for_lines "$AFPLAY_LOG" 1 &&
        [ "$(line_count "$AFPLAY_LOG")" -eq 1 ] &&
        [ "$(sed -n '1p' "$AFPLAY_LOG")" = "$class7" ]; then
        second_ok=true
    fi

    if [ "$first_ok" = true ] && [ "$second_ok" = true ]; then
        pass "router context-pressure sound fires first and latches per session"
    else
        fail "router context-pressure sound fires first and latches per session"
    fi
}

test_router_subagent_silent() {
    reset_logs
    local stdout_file="${WORKDIR}/router-subagent.out"
    local input
    input=$(jq -cn '{hook_event_name:"SubagentStop",agent_id:"agent-1"}')

    run_hook "$REPO_UNDER_TEST/starcraft-sound-router.sh" "$input" "$stdout_file"
    sleep 0.3

    if [ "$(line_count "$AFPLAY_LOG")" -eq 0 ] && [ "$(line_count "$CURL_LOG")" -eq 0 ]; then
        pass "router keeps SubagentStop/agent_id silent"
    else
        fail "router keeps SubagentStop/agent_id silent"
    fi
}

test_router_api_error_silent() {
    reset_logs
    : > "$REPO_UNDER_TEST/router.log"
    local transcript="${WORKDIR}/api-error.jsonl"
    local stdout_file="${WORKDIR}/router-api-error.out"
    write_transcript "$transcript" "The analysis is complete." 100

    run_hook "$REPO_UNDER_TEST/starcraft-sound-router.sh" "$(stop_input "$transcript" "api-error")" "$stdout_file" FAKE_CURL_MODE=error
    wait_for_lines "$CURL_LOG" 1 || true
    sleep 0.3

    if [ "$(line_count "$AFPLAY_LOG")" -eq 0 ] &&
        grep -q "Claude API error" "$REPO_UNDER_TEST/router.log"; then
        pass "router API error is logged and silent"
    else
        fail "router API error is logged and silent"
    fi
}

test_notification_hook() {
    local gas="${SOUND_ROOT}/Starcraft1/Terran/Advisor-Annotated/tadErr01-insufficient-vespene-gas.wav"
    local stdout_file="${WORKDIR}/notification.out"
    local payload

    reset_logs
    payload=$(jq -cn '{hook_event_name:"Notification",notification_type:"permission_prompt",session_id:"auth-1"}')
    run_hook "$REPO_UNDER_TEST/notification-hook.sh" "$payload" "$stdout_file"
    local permission_ok=false
    if wait_for_lines "$AFPLAY_LOG" 1 && grep -Fxq "$gas" "$AFPLAY_LOG"; then
        permission_ok=true
    fi

    reset_logs
    payload=$(jq -cn '{hook_event_name:"Notification",notification_type:"idle_prompt",session_id:"auth-1"}')
    run_hook "$REPO_UNDER_TEST/notification-hook.sh" "$payload" "$stdout_file"
    sleep 0.3
    local idle_ok=false
    if [ "$(line_count "$AFPLAY_LOG")" -eq 0 ]; then
        idle_ok=true
    fi

    reset_logs
    : > "$stdout_file"
    payload=$(jq -cn '{hook_event_name:"PreToolUse",tool_name:"ExitPlanMode",session_id:"plan-1"}')
    run_hook "$REPO_UNDER_TEST/notification-hook.sh" "$payload" "$stdout_file"
    local plan_ok=false
    if wait_for_lines "$AFPLAY_LOG" 1 &&
        grep -Fxq "$gas" "$AFPLAY_LOG" &&
        [ ! -s "$stdout_file" ]; then
        plan_ok=true
    fi

    reset_logs
    payload=$(jq -cn '{hook_event_name:"Notification",notification_type:"permission_prompt",session_id:"detached-1"}')
    run_hook "$REPO_UNDER_TEST/notification-hook.sh" "$payload" "$stdout_file" \
        TMUX=/tmp/fake-tmux TMUX_PANE=%1 FAKE_TMUX_ATTACHED=0 FAKE_TMUX_CLIENTS=client
    wait_for_lines "$AFPLAY_LOG" 1 || true
    local first_detached_count
    first_detached_count=$(line_count "$AFPLAY_LOG")

    reset_logs
    run_hook "$REPO_UNDER_TEST/notification-hook.sh" "$payload" "$stdout_file" \
        TMUX=/tmp/fake-tmux TMUX_PANE=%1 FAKE_TMUX_ATTACHED=0 FAKE_TMUX_CLIENTS=client
    sleep 0.3
    local debounce_ok=false
    if [ "$first_detached_count" -eq 1 ] && [ "$(line_count "$AFPLAY_LOG")" -eq 0 ]; then
        debounce_ok=true
    fi

    if [ "$permission_ok" = true ] && [ "$idle_ok" = true ] &&
        [ "$plan_ok" = true ] && [ "$debounce_ok" = true ]; then
        pass "notification hook handles permission, idle, ExitPlanMode, and detached debounce"
    else
        fail "notification hook handles permission, idle, ExitPlanMode, and detached debounce"
    fi
}

setup_fixture_repo
test_static_validation
test_router_classification
test_router_context_latch
test_router_subagent_silent
test_router_api_error_silent
test_notification_hook

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "All offline hook checks passed."
    exit 0
fi

echo "$FAIL_COUNT offline hook check(s) failed."
if [ -s "$STDERR_LOG" ]; then
    echo "Captured stderr:"
    sed -n '1,120p' "$STDERR_LOG"
fi
exit 1
