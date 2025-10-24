# Archive - Draft, Legacy & Debug Files

This folder contains files that are **not part of the production implementation** but are kept for reference, debugging, and historical context.

## Structure

### `versions/old_implementations`
Earlier iterations and experimental versions of the sound router.

**Contents:**
- `claude-starcraft/` - v1 & v2 implementation with AI-based classification
- `starcraft-sound-router.sh` - Original router (pre-v3)
- `test-starcraft-patterns.sh` - Pattern matching test utility
- `test-starcraft-router.sh` - Router testing harness

**Status:** Legacy - v3 is current production implementation

---

### `debugging/current-debug-hooks`
Active debugging infrastructure for troubleshooting hook execution.

**Contents:**
- `debug-hook.sh` - Main debugging hook (currently active in Claude Code settings)
- `analyze-logs.sh` - Log analysis utility
- `debug.log` - Latest hook execution log
- `hook-input.json` - Latest hook input capture
- `transcript-capture.json` - Latest transcript snapshot
- `README.md` - Debugging workflow guide

**Status:** Active - Used for diagnosing sound playback issues

**Current Hook Location:** `/Users/user/.claude/settings.json` points to `debug-hook.sh`

---

### `logs/`
Execution logs and runtime artifacts.

**Contents:**
- `router.log` - Sound router execution history

**Note:** This folder should accumulate logs during debugging. See root `.gitignore` - logs are not committed.

---

## When to Use This Archive

### For Vibe Coding / Quick Reference
Instead of digging through `git log`, check here for:
- Previous design approaches
- What was tried and why it changed
- Test utilities and patterns
- Known issues and debugging patterns

### For Production
- **DO NOT** use files from this archive for production
- Production files are in the root directory:
  - `starcraft-sound-router-v3.sh` (main router)
  - `starcraft-sounds.json` (sound mapping)
  - `validate-sound-map-v3.sh` (validation)

### For Debugging
- If the hook stops working, check `debugging/current-debug-hooks/`
- Run `analyze-logs.sh` to diagnose issues
- Review `debug.log` for execution details

---

## Migration Notes

**Migrated on:** 2025-10-24

**Reason:** Organization and discoverability - keeping draft/legacy files in one place makes them more discoverable than `git log` for ongoing vibe-coding work.

**Files Not Archived:**
- Production router and config files (root level)
- Documentation (README.md, SOUND-MAPPING-SYSTEM.md)
- Setup and validation scripts
- License

---

## Future Additions

New experimental versions, debug attempts, or legacy scripts should be added here:
- Create appropriately named subfolders
- Update this README
- **Do not commit to production areas**

