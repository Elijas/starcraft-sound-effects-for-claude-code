#!/bin/bash

# Test script for error-detection-hook.sh
# This simulates PostToolUse hook inputs with various error scenarios

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="${SCRIPT_DIR}/error-detection-hook.sh"

echo "Testing Error Detection Hook"
echo "============================="
echo

# Test 1: Bash with non-zero exit code and stderr
echo "Test 1: Bash command with exit code 1 and stderr"
cat <<'EOF' | "$HOOK_SCRIPT"
{
  "session_id": "test-123",
  "transcript_path": "/tmp/test.jsonl",
  "cwd": "/tmp",
  "permission_mode": "default",
  "hook_event_name": "PostToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "ls /nonexistent"
  },
  "tool_response": {
    "exitCode": 1,
    "stderr": "ls: /nonexistent: No such file or directory",
    "stdout": ""
  }
}
EOF
echo "✓ Test 1 completed (should play sound)"
sleep 2
echo

# Test 2: Python traceback in stdout
echo "Test 2: Python script with traceback"
cat <<'EOF' | "$HOOK_SCRIPT"
{
  "session_id": "test-456",
  "transcript_path": "/tmp/test.jsonl",
  "cwd": "/tmp",
  "permission_mode": "default",
  "hook_event_name": "PostToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "python script.py"
  },
  "tool_response": {
    "exitCode": 1,
    "stderr": "",
    "stdout": "Traceback (most recent call last):\n  File \"script.py\", line 10, in <module>\n    result = divide(10, 0)\nZeroDivisionError: division by zero"
  }
}
EOF
echo "✓ Test 2 completed (should play sound)"
sleep 2
echo

# Test 3: Read tool with error field
echo "Test 3: Read tool with error"
cat <<'EOF' | "$HOOK_SCRIPT"
{
  "session_id": "test-789",
  "transcript_path": "/tmp/test.jsonl",
  "cwd": "/tmp",
  "permission_mode": "default",
  "hook_event_name": "PostToolUse",
  "tool_name": "Read",
  "tool_input": {
    "file_path": "/path/to/missing.txt"
  },
  "tool_response": {
    "success": false,
    "error": "File not found: /path/to/missing.txt"
  }
}
EOF
echo "✓ Test 3 completed (should play sound)"
sleep 2
echo

# Test 4: Successful operation (no error)
echo "Test 4: Successful operation (should NOT play sound)"
cat <<'EOF' | "$HOOK_SCRIPT"
{
  "session_id": "test-999",
  "transcript_path": "/tmp/test.jsonl",
  "cwd": "/tmp",
  "permission_mode": "default",
  "hook_event_name": "PostToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "echo 'Hello World'"
  },
  "tool_response": {
    "exitCode": 0,
    "stderr": "",
    "stdout": "Hello World"
  }
}
EOF
echo "✓ Test 4 completed (should NOT play sound)"
echo

echo "============================="
echo "All tests completed!"
echo
echo "Expected results:"
echo "- Tests 1-3 should have played the error sound"
echo "- Test 4 should NOT have played any sound"
echo
echo "To enable debug logging, edit error-detection-hook.sh and set ENABLE_LOGGING=true"
echo "Then check: tail ~/.claude/error-detection.log"
