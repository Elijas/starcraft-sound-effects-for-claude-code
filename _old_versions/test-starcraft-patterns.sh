#!/bin/bash

TEST_MSG="$1"
MSG_LOWER=$(echo "$TEST_MSG" | tr '[:upper:]' '[:lower:]')
MSG_LEN=${#TEST_MSG}

echo "Testing message: $TEST_MSG"
echo "Length: $MSG_LEN"
echo "Lowercase: $MSG_LOWER"
echo ""

# Test each pattern
if echo "$MSG_LOWER" | grep -qE '(fatal|critical|crash|exception|cannot|failed.*test|build.*fail)'; then
    echo "✓ MATCH: Critical error pattern"
    exit 0
fi

if echo "$MSG_LOWER" | grep -qE '(not found|missing|doesn.*t exist|can.*t find|404|no such)'; then
    echo "✓ MATCH: Resource error pattern"
    exit 0
fi

if echo "$MSG_LOWER" | grep -qE '(remov|delet|clean|drop|uninstall|deprecat)'; then
    echo "✓ MATCH: Deletion pattern"
    exit 0
fi

if echo "$MSG_LOWER" | grep -qE '(completed|finished|done|successfully|fixed|resolved|passed|deployed)'; then
    echo "✓ MATCH: Success pattern"
    exit 0
fi

echo "✗ NO MATCH: Would use default (addon complete)"
