# Claude Code Instructions

## Known Limitations

### PostToolUse hooks don't fire for failed Bash commands

Claude Code's `PostToolUse` hooks are NOT called when Bash commands fail (non-zero exit codes). This is a known upstream bug, not a problem with this project's scripts.

**Impact:** `error-detection-hook.sh` cannot detect Bash failures like `command not found` or non-zero exit codes.

**Workaround:** The hook still works for:
- Exit 0 commands with error patterns in stdout (Traceback, ValueError, etc.)
- Exit 0 commands with error patterns in stderr
- Other tool failures (Read, Write, Edit, etc.)

**Track upstream:**
- https://github.com/anthropics/claude-code/issues/4831 (main feature request)
- https://github.com/anthropics/claude-code/issues/6371 (bug report with discussion)
