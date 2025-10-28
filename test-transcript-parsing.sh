#!/bin/bash
# Test Module 2: Transcript Parsing
# Tests if we can extract assistant messages from transcript

set -euo pipefail

echo "=== Testing Transcript Parsing Module ==="
echo ""

# Create a mock transcript
MOCK_TRANSCRIPT=$(mktemp)
cat > "$MOCK_TRANSCRIPT" << 'EOF'
{"role":"user","content":[{"type":"text","text":"Hello Claude"}]}
{"role":"assistant","content":[{"type":"text","text":"Hello! How can I help you today?"}]}
{"role":"user","content":[{"type":"text","text":"What is 2+2?"}]}
{"role":"assistant","content":[{"type":"text","text":"2 plus 2 equals 4."}]}
{"role":"assistant","content":[{"type":"tool_use","id":"123","name":"Bash","input":{}}]}
{"role":"assistant","content":[{"type":"text","text":"Done! The calculation is complete."}]}
EOF

echo "Created mock transcript: $MOCK_TRANSCRIPT"
echo ""

# Test the extraction logic (same as in starcraft-sound-router.sh)
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
' "$MOCK_TRANSCRIPT" 2>/dev/null)

if [ -z "$ASSISTANT_MESSAGE" ]; then
    echo "❌ FAIL: Could not extract assistant message"
    rm "$MOCK_TRANSCRIPT"
    exit 1
fi

echo "✅ Extracted message: $ASSISTANT_MESSAGE"
echo ""

# Verify it's the last text message (should be "Done! The calculation is complete.")
if [[ "$ASSISTANT_MESSAGE" == *"Done! The calculation is complete."* ]]; then
    echo "✅ Correctly extracted LAST text message (skipped tool-only message)"
else
    echo "❌ FAIL: Wrong message extracted"
    rm "$MOCK_TRANSCRIPT"
    exit 1
fi

rm "$MOCK_TRANSCRIPT"
echo ""
echo "=== Transcript Parsing Module: PASSED ==="
