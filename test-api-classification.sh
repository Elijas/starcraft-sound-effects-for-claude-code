#!/bin/bash
# Test Module 3: API Classification
# Tests if Claude API classification works

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

echo "=== Testing API Classification Module ==="
echo ""

# Load environment
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ FAIL: Missing .env file"
    exit 1
fi

export $(grep -v '^#' "$ENV_FILE" | xargs)

# Check API key
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "❌ FAIL: ANTHROPIC_API_KEY not set in .env"
    exit 1
fi

echo "✅ API key found"
echo ""

# Test classification with a simple message
TEST_MESSAGE="I found 3 bugs in your code that need to be fixed."

echo "Testing classification with message:"
echo "  \"$TEST_MESSAGE\""
echo ""

# Use the same classification logic from starcraft-sound-router.sh
prompt="Classify this Claude Code assistant response by its semantic outcome.

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
$TEST_MESSAGE
</claude_code_response>

Return only: {\"class\": N}"

response=$(curl -s -X POST https://api.anthropic.com/v1/messages \
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
        }')")

# Extract class number
class_num=$(echo "$response" | jq -r '
    .content[0].text // "" |
    try (fromjson | .class) // empty
' 2>/dev/null)

if [[ "$class_num" =~ ^[0-9]+$ ]] && [ "$class_num" -ge 1 ] && [ "$class_num" -le 14 ]; then
    echo "✅ Classification successful: Class $class_num"

    # Verify it makes sense (should be class 11 - Issues found)
    if [ "$class_num" -eq 11 ]; then
        echo "✅ Classification is correct (Class 11 - Issues found)"
    else
        echo "⚠️  Classification seems off (expected Class 11, got $class_num)"
        echo "   This might be OK - AI can vary"
    fi
else
    echo "❌ FAIL: Invalid classification response"
    echo "Response: $response"
    exit 1
fi

echo ""
echo "=== API Classification Module: PASSED ==="
