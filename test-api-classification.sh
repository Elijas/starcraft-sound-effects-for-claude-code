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

# Test classification with a validated class-1 message
TEST_MESSAGE="Here's my implementation plan (5 steps, riskiest first). Approve and I'll start."

echo "Testing classification with message:"
echo "  \"$TEST_MESSAGE\""
echo ""

# Use the same classification logic from starcraft-sound-router.sh
prompt="Classify this Claude Code assistant response by its semantic outcome.

RULES:
- Classify the state at the END of the turn. Problems encountered and RESOLVED during the turn do not count as trouble.
- If multiple classes apply, choose the HIGHEST-PRIORITY one. Priority (highest first): 12 > 11 > 10 > 9 > 8 > 1 > 7 > 5 > 6 > 4 > 3 > 2.
- TROUBLE (10-12) and STUCK (8-9) take priority even when the turn also asks the user a question.
- Class 1 means work CANNOT PROCEED without the user's reply. An optional \"want me to also...?\" offer appended to a finished deliverable does NOT count — classify the deliverable instead.
- If the assistant states further work it intends to do itself, that is IN FLIGHT (2) even if sub-tasks were completed.

AWAITING USER — the turn cannot proceed without the user's reply:
1=Needs the user's input: asks a required question, presents options or a plan to approve, requests information

IN FLIGHT — work continues, nothing failing, no reply needed:
2=Acknowledged / started / progress or status report; work still in flight or partially done

COMPLETED — a deliverable was finished this turn:
3=Analysis or explanation of code/system complete
4=Non-code deliverable complete (research report, digest, documentation, plan, summary)
5=Code change complete (feature, fix, refactor — any size). Local commits without pushing stay here.
6=Cleanup complete: the work was mostly deleting/removing code or files
7=Shipped: git push, publish, release, merge to shared branch, or production deploy completed

STUCK — Claude could not do the thing:
8=Came up empty: searched/investigated but could not find the target (file, function, answer)
9=Cannot proceed: impossible, refused, or out of scope

TROUBLE — the turn ENDS with something failing or broken:
10=Ends with failing tests/builds/tools or a worker/agent in trouble, confined to new/in-progress work
11=Previously-working behavior is now broken, or the shipped artifact is damaged (regression)
12=Catastrophic: repo or dev environment corrupt/unusable, or a destructive incident occurred (data loss, wrong-branch force-push, leaked secret)

<claude_code_response>
$TEST_MESSAGE
</claude_code_response>

Return only raw JSON, no markdown code fences: {\"class\": N}"

response=$(curl -s -X POST https://api.anthropic.com/v1/messages \
    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$(jq -n \
        --arg prompt "$prompt" \
        '{
            model: "claude-haiku-4-5-20251001",
            max_tokens: 20,
            temperature: 0,
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

if [[ "$class_num" =~ ^[0-9]+$ ]] && [ "$class_num" -ge 1 ] && [ "$class_num" -le 12 ]; then
    echo "✅ Classification successful: Class $class_num"

    # Verify it makes sense (should be class 1 - Awaiting user)
    if [ "$class_num" -eq 1 ]; then
        echo "✅ Classification is correct (Class 1 - Awaiting user)"
    else
        echo "⚠️  Classification seems off (expected Class 1, got $class_num)"
        echo "   This might be OK - AI can vary"
    fi
else
    echo "❌ FAIL: Invalid classification response"
    echo "Response: $response"
    exit 1
fi

echo ""
echo "=== API Classification Module: PASSED ==="
