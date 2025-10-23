# StarCraft Sound Mapping System v2.0

## 🎮 What is This?

A system that plays StarCraft Terran Advisor sounds when Claude Code responds, making coding **fun AND informative**!

When Claude Code talks to you, you hear:
- 🚨 **"Base is under attack!"** when Claude asks important questions
- 🚀 **"Nuclear missile ready!"** when major tasks complete
- 💥 **"Nuclear launch detected!"** when critical errors occur
- 🗑️ **"Abandoning auxiliary structure"** when files are deleted
- ✅ **"Research complete!"** when analysis finishes

Your brain learns the sounds = you know what's happening **even without looking at the screen**!

## 📊 The System

### Three Dimensions (3×3×3 = 27 combinations)

| Dimension | Values | Meaning |
|-----------|--------|---------|
| **mode** | question, action, report | How is Claude engaging? |
| **type** | constructive, destructive, analytical | What kind of work? |
| **outcome** | success, problem, neutral | How's it going? |

### Fourteen Sounds

**Attention Sounds:**
- base-is-under-attack (urgent!)
- forces-are-under-attack (warning!)

**Success Sounds:**
- nuclear-missile-ready (HUGE WIN!)
- research-complete (task done!)
- upgrade-complete (progress!)
- addon-complete (minor completion)

**Error Sounds:**
- nuclear-launch-detected (DISASTER!)
- insufficient-vespene-gas (build fail!)
- supply-depots-required (blocked!)
- landing-interrupted (stopped!)
- unacceptable-landing-zone (can't proceed!)
- not-enough-minerals (missing resource!)
- not-enough-energy (busy!)

**Special Sound:**
- abandoning-auxiliary-structure (deletion!)

## 🎯 Key Features

### 1. Questions Get Attention! 🚨
```
"Which authentication method should I use?"
→ 🚨 BASE IS UNDER ATTACK! (You need to answer!)
```

Never miss when Claude needs your input!

### 2. Destruction is Distinct 🗑️
```
"Removing old deprecated files..."
→ 🗑️ ABANDONING AUXILIARY STRUCTURE
```

Always know when files are being deleted!

### 3. Variety Prevents Boredom 🎵
```
"Task complete!" → research-complete
"Task complete!" → upgrade-complete  [different each time!]
"Task complete!" → nuclear-missile-ready
```

Common responses have multiple sounds that rotate randomly!

### 4. Severity Matters 📈
```
Minor issue:    not-enough-minerals
Normal error:   insufficient-vespene-gas
Critical error: NUCLEAR LAUNCH DETECTED!
```

The intensity matches the severity!

## 📁 Files

### Core Files (v2.0)
- **starcraft-sound-map-new.json** - Complete mapping (27 combinations)
- **starcraft-sound-router-ai-v2.sh** - AI-powered router using Claude Haiku
- **validate-sound-map-v2.sh** - Validator ensuring coverage
- **MAPPING-SYSTEM-V2.md** - Detailed technical documentation
- **UPGRADE-TO-V2.md** - Migration guide from v1.0
- **README-V2.md** - This file!

### Legacy Files (v1.0)
- starcraft-sound-map.json (old dimensions)
- starcraft-sound-router-ai.sh (old router)
- validate-sound-map.sh (old validator)

## 🚀 Quick Start

### Prerequisites
```bash
# Required
brew install jq

# API key (in ~/.bashrc or ~/.zshrc)
export ANTHROPIC_API_KEY="your-key-here"
```

### Validation
```bash
chmod +x validate-sound-map-v2.sh
./validate-sound-map-v2.sh
```

**Expected:**
```
✅ All 27 combinations are mapped
✅ All 14 sounds are used
✅ All sound files exist
✅ JSON structure is valid
```

### Usage

The router runs automatically via Claude Code hooks. To test manually:

```bash
# Make it executable
chmod +x starcraft-sound-router-ai-v2.sh

# Test it (will use default sound if no transcript)
echo '{"transcript_path":"","stop_hook_active":false}' | ./starcraft-sound-router-ai-v2.sh

# Check the log
tail -f router-v2.log
```

## 📖 Example Mappings

### Questions (Need Attention!)

| Response | Sound |
|----------|-------|
| "Which architecture should I use?" | base-is-under-attack 🚨 |
| "Build failed - retry or abort?" | forces-are-under-attack ⚠️ |
| "Feature done! Add tests?" | research-complete ✅ |

### Success Stories

| Response | Sound |
|----------|-------|
| "ALL TESTS PASSED! DEPLOYED!" | nuclear-missile-ready 🚀 |
| "Analysis complete!" | research-complete 📊 |
| "Fixed the bug!" | upgrade-complete 🔧 |
| "Done!" | addon-complete ✓ |

### Errors & Problems

| Response | Sound |
|----------|-------|
| "CATASTROPHIC BUILD FAILURE!" | nuclear-launch-detected 💥 |
| "Compilation error in 5 files" | insufficient-vespene-gas ❌ |
| "Can't find the file" | not-enough-minerals 🔍 |
| "Process interrupted" | landing-interrupted ⚠️ |

### Destructive Actions

| Response | Sound |
|----------|-------|
| "Removing old code..." | abandoning-auxiliary-structure 🗑️ |
| "Cleanup complete!" | abandoning-auxiliary-structure ✨ |
| "Deleted 20 files" | abandoning-auxiliary-structure 🚮 |

## 🧠 How It Works

```
Claude Code Response
        ↓
[Extract last message from transcript]
        ↓
[Send to Claude Haiku API]
        ↓
Haiku analyzes: {mode, type, outcome}
        ↓
[Lookup in starcraft-sound-map-new.json]
        ↓
[Randomly select if multiple options]
        ↓
[Play sound via afplay]
        ↓
🔊 You hear the sound!
```

**Smart AI Classification:**
- Uses Claude Haiku (fast, cheap, accurate)
- Detailed prompt with examples
- Falls back to default if API fails
- Logs everything for debugging

## 🎓 Learning the Sounds

After a few hours of use, your brain will learn:

| Sound Pattern | Mental Map |
|--------------|------------|
| 🚨 Alarm sounds | "Claude needs my input!" |
| 🚀 Victory sounds | "Something big completed!" |
| 💥 Explosion sounds | "Oh no, error!" |
| 🗑️ Abandoning sound | "Files being deleted" |
| 📊 Research sounds | "Found/analyzed something" |
| ⚙️ Upgrade sounds | "Making progress" |

This is the magic: **sounds become meaningful** without conscious effort!

## 📈 Statistics

From validation:
- **27 combinations** all mapped ✅
- **14 sounds** all used ✅
- **56 total sound mappings** (some combinations have 2-3 options)
- **Average 2.07 sounds per combination** (variety!)

Most used sounds:
1. addon-complete (9 combinations) - common small completions
2. research-complete (8 combinations) - analysis and discoveries
3. abandoning-auxiliary-structure (6 combinations) - all destructive work
4. upgrade-complete (6 combinations) - progress updates

Most specific sounds:
- abandoning-auxiliary-structure → ONLY destructive actions
- base-is-under-attack → ONLY urgent questions
- nuclear-missile-ready → ONLY major victories
- nuclear-launch-detected → ONLY catastrophic failures

## 🔧 Customization

### Want different sounds for a combination?

Edit `starcraft-sound-map-new.json`:

```json
{
  "mode": "report",
  "type": "constructive",
  "outcome": "success",
  "sounds": [
    "tadUpd02-research-complete.wav",
    "tadUPD06-upgrade-complete.wav",
    "TAdUpd07-nuclear-missile-ready.wav"  // Add or remove sounds!
  ]
}
```

Then validate:
```bash
./validate-sound-map-v2.sh
```

### Want to adjust AI classification?

Edit the PROMPT in `starcraft-sound-router-ai-v2.sh` to give Haiku better guidance.

## 🐛 Troubleshooting

### No sounds playing?
```bash
# Check the log
tail -20 router-v2.log

# Common issues:
# - No ANTHROPIC_API_KEY (will use defaults)
# - Sound files not found (check path)
# - afplay not working (macOS only)
```

### Wrong sound for a response?
```bash
# Check what Haiku classified it as
grep "Dimensions" router-v2.log | tail -5

# Example output:
# Dimensions - mode: action, type: constructive, outcome: success
```

If consistently wrong, adjust the prompt examples!

### Want more logging?
```bash
export STARCRAFT_DEBUG=1
# Now router will echo to stderr too
```

## 🎯 Design Philosophy

1. **Informative** - Consistent sound → meaning mapping
2. **Fun** - StarCraft nostalgia + variety
3. **Attention** - Questions get urgent sounds
4. **Semantic** - Natural intuitive dimensions
5. **Complete** - Every sound used, every case covered
6. **Learnable** - Your brain naturally picks up patterns

## 🙏 Credits

- **StarCraft Sounds** - Blizzard Entertainment
- **Claude Haiku** - AI classification (Anthropic)
- **Claude Code** - Hook system for integration

## 📝 Version History

**v2.0** (Current)
- New dimension system: mode/type/outcome
- Questions get attention sounds
- Analytical work is distinct
- Better variety (2-3 sounds per common case)
- All 14 sounds used strategically
- Comprehensive documentation

**v1.0** (Legacy)
- Original system: severity/magnitude/context
- Questions lumped into "warning"
- Less variety
- Still functional (backed up as *-v1.json)

---

## 🎮 Enjoy!

Now when you code with Claude, you'll hear:
- 🚨 When you need to answer
- 🚀 When you achieve victory
- 💥 When things explode
- 🗑️ When things get deleted
- 📊 When discoveries are made

**Your coding session just got a StarCraft soundtrack!** 🎵

For detailed technical docs: See `MAPPING-SYSTEM-V2.md`
For migration guide: See `UPGRADE-TO-V2.md`
For validation: Run `./validate-sound-map-v2.sh`
