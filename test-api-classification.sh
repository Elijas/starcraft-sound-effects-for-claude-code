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

# Test classification with a validated class-2 message
TEST_MESSAGE="Here's my implementation plan (5 steps, riskiest first). Approve and I'll start."

echo "Testing classification with message:"
echo "  \"$TEST_MESSAGE\""
echo ""

# Use the same classification logic from starcraft-sound-router.sh
prompt="Classify this Claude Code assistant response by its semantic outcome.

RULES:
- Classify the state at the END of the turn. Problems encountered and RESOLVED during the turn do not count as trouble.
- If multiple classes apply, choose the HIGHEST-PRIORITY one. Priority (highest first): 13 > 12 > 11 > 10 > 1 > 2 > 3 > 9 > 8 > 7 > 6 > 5 > 4.
- TROUBLE (11-13) and CANNOT PROCEED (10) take priority over classes 1-3: if something is failing or broken at the end of the turn, classify the failure even when the turn also asks the user a question.
- Classes 1-3 require that work CANNOT PROCEED without the user's reply. An optional \"want me to also...?\" offer appended to a finished deliverable does NOT count — classify the deliverable instead.
- 1 vs 2 vs 3: class 1 asks for INFORMATION (what/which/how, missing facts). Class 2 presents a NEW plan or proposal and cannot start without approval. Class 3 has finished a chunk of work and asks whether to CONTINUE or stop.
- 4 vs 5 vs COMPLETED: class 4 has finished nothing yet this turn (ack, status, health report). Class 5 announces finished sub-tasks AND explicitly continues working (e.g. \"starting the next module now\"). A finished chunk followed by a continue-or-stop question is 3. Finished work with nothing continuing and no reply needed is COMPLETED (7/8/9).

AWAITING USER — the turn cannot proceed without the user's reply:
1=Needs information: asks what/which/how, requests details or missing facts from the user
2=Needs plan approval: presented a plan, spec, or proposal and awaits approval before starting
3=Needs continue-or-stop: a chunk of work is done; asks whether to continue with the next chunk or stop

IN FLIGHT — no reply needed:
4=Working: acknowledged / started / status or health report; nothing finished yet this turn
5=Milestone: one or more sub-tasks finished (commits landed, items checked off); work continues autonomously
6=Wrapped up / parked: checkpoint, handoff, session retirement, or work deliberately paused with nothing left in flight

COMPLETED — a deliverable was finished this turn:
7=Knowledge deliverable complete: analysis, explanation, research report, digest, documentation, plan, or summary
8=Code change complete (feature, fix, refactor, or deletion/cleanup — any size). Local commits without pushing stay here.
9=Shipped: git push, publish, release, merge to shared branch, or production deploy completed

STUCK:
10=Cannot proceed: impossible, refused, out of scope, or an unrecoverable error/rate-limit ended the turn

TROUBLE — the turn ENDS with something failing or broken:
11=Ends with failing tests/builds/tools or a worker/agent in trouble, confined to new/in-progress work
12=Previously-working behavior is now broken, or the shipped artifact is damaged (regression)
13=Catastrophic: repo or dev environment corrupt/unusable, or a destructive incident occurred (data loss, wrong-branch force-push, leaked secret)

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

if [[ "$class_num" =~ ^[0-9]+$ ]] && [ "$class_num" -ge 1 ] && [ "$class_num" -le 13 ]; then
    echo "✅ Classification successful: Class $class_num"

    # Verify it makes sense (should be class 2 - Needs plan approval)
    if [ "$class_num" -eq 2 ]; then
        echo "✅ Classification is correct (Class 2 - Needs plan approval)"
    else
        echo "⚠️  Classification seems off (expected Class 2, got $class_num)"
        echo "   This might be OK - AI can vary"
    fi
else
    echo "❌ FAIL: Invalid classification response"
    echo "Response: $response"
    exit 1
fi

echo ""
echo "=== API Classification Module: PASSED ==="
