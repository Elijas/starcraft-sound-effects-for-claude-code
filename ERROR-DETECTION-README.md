# Error Detection Hook for Claude Code

## Overview

Algorithmic (NO AI) error detection hook that plays a StarCraft error sound when Claude Code tool operations encounter errors.

**Error sound**: configured via the `error_sound` entry in `sound-config.json` (paths relative to `STARCRAFT_ROOT_DIR`). By default this is a random Goliath unit sound from `Starcraft1/Terran/Goliath/`.

## How It Works

### Hook Configuration

**Hook Event**: `PostToolUse` (runs immediately after tool execution)

**Monitored Tools**:
- `Bash` - Shell commands
- `BashOutput` - Background shell output
- `Read` - File reading
- `Write` - File writing
- `Edit` - File editing
- `Glob` - Pattern matching
- `Grep` - Content search
- `WebFetch` - Web requests
- `WebSearch` - Search operations

### Error Detection Patterns (Algorithmic Only)

The hook uses pure regex pattern matching to detect:

1. **Exit Codes**: Any non-zero exit code (1-255)
2. **stderr Content**: Contains error keywords:
   - `traceback`, `error:`, `exception`, `failed`, `fatal`, `critical`
   - `syntax error`, `cannot find`, `permission denied`
   - `no such file`, `command not found`, `connection refused`, `timeout`
3. **Error Field**: Non-empty `error` field in tool response
4. **Success Flag**: `success: false` in tool response
5. **Python Errors** in stdout:
   - `Traceback (most recent call last):`
   - `SyntaxError`, `ValueError`, `TypeError`, `KeyError`, `IndexError`
   - `AttributeError`, `ImportError`, `RuntimeError`, `NameError`
6. **JavaScript Errors** in stdout:
   - `Error:`, `TypeError:`, `ReferenceError:`, `SyntaxError:`, `RangeError:`

## Configuration

### Settings Location
`~/.claude/settings.json`

### Current Configuration
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash|BashOutput|Read|Write|Edit|Glob|Grep|WebFetch|WebSearch",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/starcraft-sound-effects-for-claude-code/error-detection-hook.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/starcraft-sound-effects-for-claude-code/starcraft-sound-router.sh"
          }
        ]
      }
    ]
  }
}
```

## Testing

### Run Test Suite
```bash
cd /path/to/starcraft-sound-effects-for-claude-code
./test-error-detection.sh
```

The test script simulates 4 scenarios:
1. ✅ Bash with exit code 1 and stderr → Should play sound
2. ✅ Python traceback in stdout → Should play sound
3. ✅ Read tool with error field → Should play sound
4. ❌ Successful operation → Should NOT play sound

### Live Testing
To test with actual Claude Code operations:

1. **Restart Claude Code** (required for hooks to reload)
2. **Run a command that fails**:
   ```
   Read a file that doesn't exist
   Run a Python script with an error
   Execute a shell command that returns non-zero exit code
   ```
3. **Listen for the error sound** (a random Goliath unit sound)

## Debugging

### Enable Logging
Edit `error-detection-hook.sh` and change:
```bash
ENABLE_LOGGING=true  # Set to true to enable logging
```

### View Logs
```bash
tail -f ~/.claude/error-detection.log
```

Log entries show:
- Which tool triggered the hook
- What error patterns were detected
- Whether the sound was played

### Common Issues

**No sound playing:**
1. Restart Claude Code (hooks are cached at startup)
2. Verify the configured error-sound folder exists (see `sound-config.json` → `error_sound`): `ls -lh "$STARCRAFT_ROOT_DIR/Starcraft1/Terran/Goliath/"`
3. Test audio manually with any file from it: `afplay "$(ls "$STARCRAFT_ROOT_DIR"/Starcraft1/Terran/Goliath/*.wav | head -1)"`
4. Enable logging and check logs

**Sound playing for non-errors:**
- Check logs to see which pattern triggered
- Adjust regex patterns in `error-detection-hook.sh`
- Report false positives for pattern refinement

**Hook not running:**
1. Check Claude Code debug logs: `~/.claude/debug/latest`
2. Verify workspace is trusted (hooks disabled in untrusted workspaces)
3. Check hook is registered: Look for "PostToolUse" in settings

## Architecture

### How Both Hooks Work Together

**Error Detection Hook (PostToolUse)**:
- Runs immediately after each tool execution
- Detects errors algorithmically (regex patterns)
- Plays power-down sound on errors
- Fast, lightweight, no AI

**Semantic Classification Hook (Stop)**:
- Runs after Claude finishes entire response
- Uses AI to classify response meaning
- Plays contextual sounds (14 categories)
- Semantic, comprehensive, AI-powered

Both hooks are **independent and complementary**:
- Error sound = Immediate feedback on tool failures
- Semantic sound = Overall response outcome

## Files

```
starcraft-sound-effects-for-claude-code/
├── error-detection-hook.sh         # Main error detection hook
├── test-error-detection.sh         # Test suite for error detection
├── ERROR-DETECTION-README.md       # This file
├── starcraft-sound-router.sh       # Semantic classification hook (AI)
├── sound-config.json               # Sound mappings (semantic + error sounds)
└── README.md                       # Main project README
```

## Customization

### Change Sound File
Edit the `error_sound` entry in `sound-config.json` (paths relative to `STARCRAFT_ROOT_DIR`):
```json
"error_sound": { "path": "Starcraft1/Terran/Goliath/", "exclude": ["TGoDth00.wav"] }
```
A folder plays a random `.wav` from it; a single-file path plays that file.

### Add More Tools
Edit `~/.claude/settings.json` matcher:
```json
"matcher": "Bash|BashOutput|Read|Write|Edit|YourToolHere"
```

### Adjust Error Patterns
Edit `error-detection-hook.sh` and modify the regex patterns in:
- Pattern 2: stderr checking
- Pattern 5: stdout Python/JS error detection

### Change Timeout
Edit `~/.claude/settings.json`:
```json
"timeout": 10  // seconds
```

## Performance

- **Latency**: < 50ms (pure regex matching)
- **CPU**: Minimal (bash + jq + grep)
- **Cost**: $0 (no AI API calls)
- **Reliability**: High (algorithmic, deterministic)

## Limitations

- **Algorithmic only**: Can't understand semantic context
- **False positives**: May trigger on log messages containing "error"
- **False negatives**: Won't catch errors without standard patterns
- **macOS only**: Uses `afplay` (Linux/Windows need different audio commands)

## Future Enhancements

- [ ] Platform detection (Linux: `aplay`, Windows: PowerShell audio)
- [ ] Configurable severity levels (different sounds for warnings vs errors)
- [ ] Rate limiting (avoid sound spam on multiple errors)
- [ ] Integration with notification systems
- [ ] Custom pattern configuration via JSON file
- [ ] Sound suppression for specific tools/patterns

## Credits

Part of the [StarCraft Sound Effects for Claude Code](README.md) project.

---

**"Not enough minerals!"** - You now have *enough* error detection. Happy coding, Commander! 🎮
