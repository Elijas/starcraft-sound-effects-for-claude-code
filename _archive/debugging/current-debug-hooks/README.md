# Debugging Hook - Workflow

## How to Debug Together

This folder contains debugging scripts to help us diagnose why the StarCraft sound effects hook isn't playing sounds.

### Step 1: Hook is Active
The debug hook is now installed in your Claude Code settings (`~/.claude/settings.json`).

**Current hook command**: `/Users/user/Development/starcraft-sound-effects-for-claude-code/_scratchpad/debug-hook.sh`

### Step 2: Trigger the Hook
Run any Claude Code command that triggers the "Stop" hook. For example:
- Ask Claude a question and wait for a response
- Or manually trigger by running: `claude-code --text "test"`

### Step 3: Analyze Logs
After triggering, run this command to see what happened:
```bash
/Users/user/Development/starcraft-sound-effects-for-claude-code/_scratchpad/analyze-logs.sh
```

### What Gets Captured
- **debug.log** - Full execution log with timestamps
- **hook-input.json** - The exact JSON input the hook received
- **transcript-capture.json** - Copy of the transcript file at time of hook
- **router-execution.log** - Output from running the production router

### Files in This Scratchpad

| File | Purpose |
|------|---------|
| `debug-hook.sh` | Main debugging hook - captures all data and calls production router |
| `analyze-logs.sh` | Run after hook fires to see diagnostic output |
| `README.md` | This file |
| `debug.log` | Generated - full debug log |
| `hook-input.json` | Generated - hook input JSON |
| `transcript-capture.json` | Generated - captured transcript |

## Workflow

1. **I ask you to run Claude Code** with a specific prompt
2. **Hook fires and captures data** to `_scratchpad/`
3. **You run**: `./analyze-logs.sh`
4. **You show me the output**
5. **We analyze together** what went wrong
6. **I make fixes** based on findings
7. **Repeat** if needed

## Quick Test

Try this simple test:
```bash
cd /Users/user/Development/starcraft-sound-effects-for-claude-code/_scratchpad
./analyze-logs.sh
```

This will show the current state without needing to trigger Claude Code yet.

## Next Steps

Please:
1. Run `claude-code` or trigger a normal interaction
2. Wait for it to complete
3. Run: `./analyze-logs.sh`
4. Share the output with me

Let me know when you're ready!
