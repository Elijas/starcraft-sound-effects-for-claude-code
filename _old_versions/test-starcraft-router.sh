#!/bin/bash

# Test harness for StarCraft router
# Simulates the hook environment with real captured data

TEMP_TRANSCRIPT=$(mktemp)

# Create a mock transcript with the "I'm ready!" message
cat > "$TEMP_TRANSCRIPT" << 'EOF'
{"type":"summary","summary":"Test Session","leafUuid":"test-uuid"}
{"parentUuid":null,"isSidechain":false,"userType":"external","cwd":"/Users/user/.claude","sessionId":"test-session","version":"2.0.25","gitBranch":"","type":"user","message":{"role":"user","content":"say that youre ready"},"uuid":"user-msg","timestamp":"2025-10-23T12:25:34.594Z"}
{"parentUuid":"user-msg","isSidechain":false,"userType":"external","cwd":"/Users/user/.claude","sessionId":"test-session","version":"2.0.25","gitBranch":"","message":{"model":"claude-sonnet-4-5-20250929","id":"msg_test","type":"message","role":"assistant","content":[{"type":"text","text":"I'm ready! How can I help you today?"}],"stop_reason":null,"stop_sequence":null},"requestId":"req_test","type":"assistant","uuid":"assistant-msg","timestamp":"2025-10-23T12:25:38.454Z"}
EOF

# Create mock hook input (JSON on stdin)
HOOK_INPUT=$(cat <<EOF
{
  "session_id": "test-session",
  "transcript_path": "$TEMP_TRANSCRIPT",
  "cwd": "/Users/user/.claude",
  "permission_mode": "bypassPermissions",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
EOF
)

echo "Testing StarCraft router..."
echo "Mock transcript: $TEMP_TRANSCRIPT"
echo ""
echo "Hook input:"
echo "$HOOK_INPUT"
echo ""
echo "Running router..."
echo ""

# Run the router with mock input
echo "$HOOK_INPUT" | /Users/user/bin/starcraft-sound-router-fast.sh

echo ""
echo "Test complete. You should have heard a sound."
echo "Cleaning up..."

rm -f "$TEMP_TRANSCRIPT"
