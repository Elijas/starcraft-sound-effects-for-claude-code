#!/bin/bash
# Test Module 4: End-to-End Test
# Simulates complete hook execution with mock data

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Testing End-to-End Hook Execution ==="
echo ""

# Create a mock transcript with a complete conversation
MOCK_TRANSCRIPT=$(mktemp)
cat > "$MOCK_TRANSCRIPT" << 'EOF'
{"role":"user","content":[{"type":"text","text":"Fix the authentication bug"}]}
{"role":"assistant","content":[{"type":"text","text":"I'll help you fix the authentication bug. Let me first search for the auth code."}]}
{"role":"assistant","content":[{"type":"tool_use","id":"1","name":"Grep","input":{"pattern":"auth"}}]}
{"role":"user","content":[{"type":"tool_result","tool_use_id":"1","content":"Found auth.js"}]}
{"role":"assistant","content":[{"type":"text","text":"Fixed! The authentication bug has been resolved. The issue was in the token validation logic."}]}
EOF

echo "Created mock transcript: $MOCK_TRANSCRIPT"
echo ""

# Create mock hook input
MOCK_HOOK_INPUT=$(mktemp)
cat > "$MOCK_HOOK_INPUT" << EOF
{
  "transcriptPath": "$MOCK_TRANSCRIPT",
  "stop_hook_active": false
}
EOF

echo "Testing starcraft-sound-router.sh with mock input..."
echo ""

# Run the router script with mock input
if cat "$MOCK_HOOK_INPUT" | "${SCRIPT_DIR}/starcraft-sound-router.sh" 2>&1; then
    echo ""
    echo "✅ Script executed successfully"
else
    echo ""
    echo "❌ FAIL: Script failed"
    rm "$MOCK_TRANSCRIPT" "$MOCK_HOOK_INPUT"
    exit 1
fi

# Check if log was updated
if tail -1 "${SCRIPT_DIR}/router.log" | grep -q "Playing sound"; then
    echo "✅ Log updated with sound playback"
    echo ""
    echo "Last log entry:"
    tail -3 "${SCRIPT_DIR}/router.log" | head -3
else
    echo "❌ FAIL: Log not updated"
    rm "$MOCK_TRANSCRIPT" "$MOCK_HOOK_INPUT"
    exit 1
fi

rm "$MOCK_TRANSCRIPT" "$MOCK_HOOK_INPUT"
echo ""
echo "=== End-to-End Test: PASSED ==="
