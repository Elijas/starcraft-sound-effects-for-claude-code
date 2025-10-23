# Upgrading to StarCraft Sound Mapping v2.0

## What's New in v2.0

The v2.0 system redesigns the dimension mapping to be **more intuitive, more fun, and more informative**!

### Key Improvements

1. **Questions Now Have Their Own Category!** 🎯
   - When Claude asks you something, you hear urgent "attention required" sounds
   - "Base is under attack!" = "Claude needs an answer!"
   - No more missing important questions

2. **Better Work Type Classification** 📊
   - `analytical` work (reading/searching) is now separate
   - `constructive` (building/fixing) and `destructive` (deleting/cleanup) are clearer
   - `mode` (question/action/report) clarifies engagement style

3. **More Variety, Less Boredom** 🎵
   - Common responses have 2-3 sound options
   - System randomly picks one each time
   - Your ears won't get fatigued!

4. **All Sounds Used Strategically** ✅
   - Every sound has a clear purpose
   - "abandoning-auxiliary-structure" = deletion sound
   - "nuclear-missile-ready" = major victory sound
   - "base-is-under-attack" = urgent question sound

## Dimension Comparison

### Old System (v1.0)
```
severity: error / warning / success
magnitude: major / normal / minor
context: destructive / constructive / neutral
```

**Problems:**
- Questions were lumped into "warning" (confusing!)
- "neutral" context was a catch-all
- Analytical work wasn't distinct

### New System (v2.0)
```
mode: question / action / report
type: constructive / destructive / analytical
outcome: success / problem / neutral
```

**Improvements:**
- Questions are their own mode (gets attention sounds!)
- Type clarifies what KIND of work
- Mode clarifies HOW Claude is engaging
- More semantic and intuitive

## Quick Start Guide

### Installation

1. **Backup your old system:**
   ```bash
   cp starcraft-sound-map.json starcraft-sound-map-v1-backup.json
   cp starcraft-sound-router-ai.sh starcraft-sound-router-ai-v1-backup.sh
   ```

2. **Use the new files:**
   - `starcraft-sound-map-new.json` - New mapping (already created ✅)
   - `starcraft-sound-router-ai-v2.sh` - New router (already created ✅)
   - `validate-sound-map-v2.sh` - New validator (already created ✅)

3. **Test it:**
   ```bash
   ./validate-sound-map-v2.sh
   ```
   Should show: ✅ All validations passed!

4. **Switch to v2:**
   ```bash
   # Option A: Rename files to use v2 as default
   mv starcraft-sound-router-ai.sh starcraft-sound-router-ai-v1.sh
   mv starcraft-sound-router-ai-v2.sh starcraft-sound-router-ai.sh
   mv starcraft-sound-map.json starcraft-sound-map-v1.json
   mv starcraft-sound-map-new.json starcraft-sound-map.json

   # Option B: Update your Claude Code hook to use v2 files directly
   # (edit your .claude/hooks/assistant-response-stop.sh to point to *-v2.sh)
   ```

## Sound Mapping Examples

### Questions (mode = question)

| Response | Classification | Sound |
|----------|---------------|-------|
| "Which library should I use?" | question/constructive/neutral | base-is-under-attack 🚨 |
| "Build failed - how to fix?" | question/constructive/problem | forces-are-under-attack ⚠️ |
| "Feature complete! Add tests?" | question/constructive/success | research-complete ✅ |
| "Should I delete this old code?" | question/destructive/neutral | addon-complete |
| "Can't find file - search elsewhere?" | question/analytical/problem | not-enough-minerals |

### Actions (mode = action)

| Response | Classification | Sound |
|----------|---------------|-------|
| "Deploying to production!" | action/constructive/success | nuclear-missile-ready 🚀 |
| "Build failed with errors!" | action/constructive/problem | nuclear-launch-detected 💥 |
| "Implementing feature X..." | action/constructive/neutral | upgrade-complete ⚙️ |
| "Removing old files..." | action/destructive/neutral | abandoning-auxiliary-structure 🗑️ |
| "Searching codebase..." | action/analytical/neutral | research-complete 🔍 |

### Reports (mode = report)

| Response | Classification | Sound |
|----------|---------------|-------|
| "All tests passed!" | report/constructive/success | nuclear-missile-ready 🎉 |
| "Found 5 critical bugs" | report/constructive/problem | nuclear-launch-detected 🐛 |
| "Here's what I built..." | report/constructive/neutral | upgrade-complete 📋 |
| "Cleanup complete!" | report/destructive/success | abandoning-auxiliary-structure ✨ |
| "Here are the 15 files..." | report/analytical/neutral | research-complete 📁 |

## Sound Guide

### 🚨 Attention Sounds (Questions!)
- **base-is-under-attack** - Urgent important questions
- **forces-are-under-attack** - Problem questions needing decisions

### ✅ Success Sounds
- **nuclear-missile-ready** - MAJOR victories, huge successes
- **research-complete** - Tasks completed, discoveries made
- **upgrade-complete** - Incremental progress, regular completions
- **addon-complete** - Minor completions, trivial operations (DEFAULT)

### ❌ Error Sounds
- **nuclear-launch-detected** - CATASTROPHIC failures
- **insufficient-vespene-gas** - Build/compilation failures
- **supply-depots-required** - Capacity limits, dependencies blocking
- **landing-interrupted** - Operations interrupted, process blocked
- **unacceptable-landing-zone** - Prerequisites not met
- **not-enough-minerals** - Can't find resources/files
- **not-enough-energy** - Resources busy, can't proceed

### 🗑️ Special Sound
- **abandoning-auxiliary-structure** - THE deletion/cleanup sound

## Testing the New System

Try these scenarios to hear the different sounds:

```bash
# Question sounds
"Should I use TypeScript or JavaScript?"
→ base-is-under-attack (urgent question!)

# Success sounds
"All 50 tests passed! Feature deployed successfully!"
→ nuclear-missile-ready (major victory!)

# Error sounds
"Build completely failed with 20 compilation errors!"
→ nuclear-launch-detected (catastrophic!)

# Deletion sounds
"Successfully removed all deprecated code and old backups"
→ abandoning-auxiliary-structure (cleanup!)

# Analytical sounds
"Found the bug! It's in auth.ts line 42"
→ research-complete (discovery!)
```

## Validation

Run the validator anytime:

```bash
./validate-sound-map-v2.sh
```

**Expected output:**
```
✅ All 27 combinations are mapped
✅ All 14 sounds are used
✅ All sound files exist
✅ JSON structure is valid

The mapping system is ready to use!
```

## Sound Usage Statistics

From validation results:
- **Most used**: addon-complete (9 combos), research-complete (8 combos)
- **Most specific**: abandoning-auxiliary-structure (destructive only)
- **Attention getters**: base-is-under-attack, forces-are-under-attack (questions)
- **Big moments**: nuclear-missile-ready (victories), nuclear-launch-detected (disasters)

## Troubleshooting

### Sounds not playing?
1. Check router log: `tail -f router-v2.log`
2. Verify API key: `echo $ANTHROPIC_API_KEY`
3. Run validator: `./validate-sound-map-v2.sh`

### Wrong sounds playing?
1. Check classification in log: `tail router-v2.log`
2. Haiku's classification is visible in the log
3. May need to adjust prompt if consistently wrong

### Want to customize?
1. Edit `starcraft-sound-map-new.json`
2. Add/remove sounds from combinations
3. Run `./validate-sound-map-v2.sh` to verify

## Philosophy

The v2.0 system follows these principles:

1. **Informative** - Sounds map consistently to meanings
2. **Fun** - Variety prevents boredom
3. **Attentive** - Questions get urgent sounds
4. **Semantic** - Natural classification that makes sense
5. **Complete** - All sounds used, all combinations covered

Your brain will learn the mapping after a few sessions:
- "That's the question sound!" (base under attack)
- "That's the deletion sound!" (abandoning structure)
- "That's the victory sound!" (nuclear missile ready)
- "That's the disaster sound!" (nuclear launch detected)

## Feedback

As you use the system, pay attention to:
- Do the sounds match your expectations?
- Are questions getting the right "attention" sounds?
- Is the variety preventing boredom?
- Are there any misclassifications?

The AI (Haiku) learns to classify based on the prompt, so if you notice patterns of wrong classifications, we can adjust the prompt in the router script!

---

Enjoy your new StarCraft sound system! 🎮🔊
