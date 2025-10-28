#!/bin/bash
# Master Test Runner
# Runs all module tests in sequence

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  StarCraft Sound Router - Module Test Suite               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Make all test scripts executable
chmod +x "${SCRIPT_DIR}"/test-*.sh

TESTS=(
    "test-sound-playback.sh"
    "test-transcript-parsing.sh"
    "test-api-classification.sh"
    "test-end-to-end.sh"
)

PASSED=0
FAILED=0
FAILED_TESTS=()

for test in "${TESTS[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if "${SCRIPT_DIR}/${test}"; then
        PASSED=$((PASSED + 1))
        echo ""
    else
        FAILED=$((FAILED + 1))
        FAILED_TESTS+=("$test")
        echo ""
        echo "❌ $test FAILED"
        echo ""
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Test Results                                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  ✅ Passed: $PASSED"
echo "  ❌ Failed: $FAILED"
echo ""

if [ $FAILED -gt 0 ]; then
    echo "Failed tests:"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    echo ""
    exit 1
else
    echo "🎉 All tests passed!"
    echo ""
    echo "Next steps:"
    echo "1. Restart Claude Code completely"
    echo "2. Have a conversation with me"
    echo "3. You should hear StarCraft sounds when I respond!"
    echo ""
    echo "If still no sound, check:"
    echo "  - Debug logs: grep -i 'stop' ~/.claude/debug/latest | tail -20"
    echo "  - Router logs: tail -20 router.log"
    echo ""
fi
