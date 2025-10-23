# StarCraft Sound Mapping System v2.0

## Overview

This system maps Claude Code responses to StarCraft Terran Advisor sounds using a 3-dimensional classification system. The goal is to make sounds **informative** (your brain learns what each sound means) while keeping them **fun** (variety prevents boredom).

## The Three Dimensions

### 1. MODE (How Claude engages with you)

| Value | Description | Key Indicators |
|-------|-------------|----------------|
| **question** | Claude is asking for user input, decisions, or clarifications - **needs attention!** | "Should I...", "Which...", "What would you like...", "How should I..." |
| **action** | Claude is actively executing work, doing tasks, in progress | "Implementing...", "Building...", "Removing...", "Searching...", "...ing" verbs |
| **report** | Claude is informing, explaining, or reporting results | "Here's...", "I found...", "Successfully...", "Failed to...", past tense |

### 2. TYPE (What kind of work)

| Value | Description | Key Indicators |
|-------|-------------|----------------|
| **constructive** | Building, creating, fixing, implementing, adding code | Writing files, implementing features, fixing bugs, building, compiling, testing |
| **destructive** | Deleting, removing, cleaning up, destroying code | Deleting files, removing code, cleaning up, purging, abandoning |
| **analytical** | Reading, searching, exploring, understanding code | Searching, reading, exploring, analyzing, reviewing, understanding |

### 3. OUTCOME (How's it going)

| Value | Description | Key Indicators |
|-------|-------------|----------------|
| **success** | Positive, went well, completed successfully, found | "Successfully...", "Complete!", "Done!", "All tests passed", "Found it!" |
| **problem** | Error, failure, blocked, not found, issue encountered | "Error", "Failed", "Can't", "Unable to", "Blocked", "Not found" |
| **neutral** | Normal operation, in-progress, informational, no particular outcome | "Here's...", "I'm...", "Let me...", no strong positive/negative indicators |

## Sound Categories

### Attention Sounds (for questions!)
- **base-is-under-attack** - URGENT important questions that need immediate attention
- **forces-are-under-attack** - Warning-level questions, problems that need decisions

### Success/Completion Sounds
- **nuclear-missile-ready** - MAJOR victories, huge successes, critical completions
- **research-complete** - Research/analysis finished, tasks completed, discoveries made
- **upgrade-complete** - Incremental progress, regular completions, updates
- **addon-complete** - Minor successes, small completions, trivial operations (DEFAULT)

### Error Sounds
- **nuclear-launch-detected** - CATASTROPHIC failures, system broken, critical errors
- **insufficient-vespene-gas** - Build failures, compilation errors, can't construct
- **additional-supply-depots-required** - Capacity limits, quota exceeded, dependencies blocking
- **landing-sequence-interrupted** - Operations interrupted, process blocked, stopped mid-way
- **unacceptable-landing-zone** - Prerequisites not met, conditions not satisfied
- **not-enough-minerals** - Missing resources, can't find files, something needed is absent
- **not-enough-energy** - Resources busy, operations blocked, can't proceed

### Special Sounds
- **abandoning-auxiliary-structure** - THE deletion sound! Used for remove/cleanup/destroy actions

## Key Design Principles

### 1. Questions Get Attention
When Claude asks you something, you hear **urgent attention sounds**:
- "Which approach should I use?" → **base-is-under-attack** (urgent!)
- "Build failed, how to fix?" → **forces-are-under-attack** (needs decision)
- "Want me to add tests?" → **research-complete** (positive question)

This makes sure you never miss when Claude needs your input!

### 2. Destruction is Distinct
All deletion/removal/cleanup actions use **abandoning-auxiliary-structure** as the primary sound:
- "Removing old files..." → **abandoning-auxiliary-structure**
- "Cleanup complete!" → **abandoning-auxiliary-structure**
- "Should I delete this?" → **abandoning-auxiliary-structure**

This creates a strong mental association: "That sound = something is being deleted"

### 3. Variety Prevents Boredom
Common response types have **multiple sound options** that are randomly selected:
- Success completion: 3 sounds (nuclear-missile-ready, research-complete, upgrade-complete)
- Build failures: 3 sounds (nuclear-launch-detected, insufficient-vespene-gas, landing-interrupted)
- Information reporting: 3 sounds (research-complete, upgrade-complete, addon-complete)

You won't hear the same sound over and over!

### 4. Severity Matters
- **nuclear-launch-detected** = System is broken, catastrophic failure
- **insufficient-vespene-gas** = Normal build error
- **not-enough-minerals** = Minor issue, can't find one file

The intensity of the sound matches the severity of the situation.

### 5. All Sounds Used
The mapping ensures **all 14 StarCraft sounds** get used regularly, so the system takes full advantage of the available audio palette.

## Example Classifications

### Questions (mode = question)

```
"Which authentication library should I use?"
→ mode=question, type=constructive, outcome=neutral
→ base-is-under-attack (important decision!)

"Feature complete! Want me to add tests too?"
→ mode=question, type=constructive, outcome=success
→ research-complete

"Can't delete file - it's locked. Force it?"
→ mode=question, type=destructive, outcome=problem
→ forces-are-under-attack
```

### Actions (mode = action)

```
"Deploying to production now!"
→ mode=action, type=constructive, outcome=success
→ nuclear-missile-ready

"Build failed with 15 errors!"
→ mode=action, type=constructive, outcome=problem
→ nuclear-launch-detected

"Searching codebase for pattern X..."
→ mode=action, type=analytical, outcome=neutral
→ research-complete

"Removing deprecated files..."
→ mode=action, type=destructive, outcome=neutral
→ abandoning-auxiliary-structure
```

### Reports (mode = report)

```
"All tests passed! Feature deployed successfully!"
→ mode=report, type=constructive, outcome=success
→ nuclear-missile-ready

"Found 5 critical security vulnerabilities in the code!"
→ mode=report, type=analytical, outcome=problem
→ nuclear-launch-detected

"Cleanup complete - removed 20 old files"
→ mode=report, type=destructive, outcome=success
→ abandoning-auxiliary-structure

"Here are the 15 files I found..."
→ mode=report, type=analytical, outcome=neutral
→ research-complete
```

## Mental Mapping Guide

After using the system, your brain will learn:

| Sound | Mental Association |
|-------|-------------------|
| base-is-under-attack | "Claude needs an important answer from me!" |
| forces-are-under-attack | "There's a problem, Claude needs my decision" |
| nuclear-missile-ready | "Big win! Something major completed!" |
| research-complete | "Task done, analysis finished, found something" |
| upgrade-complete | "Making progress, incremental improvement" |
| addon-complete | "Small update, minor completion, quick note" |
| nuclear-launch-detected | "Oh no, something broke badly!" |
| insufficient-vespene-gas | "Build failed, can't compile" |
| supply-depots | "Hit a limit, dependencies blocking" |
| landing-interrupted | "Process stopped, operation blocked" |
| unacceptable-landing-zone | "Prerequisites missing, can't proceed" |
| not-enough-minerals | "Can't find something needed" |
| not-enough-energy | "Resources busy, blocked" |
| abandoning-structure | "Something is being deleted" |

## Statistics

- **Total combinations**: 27 (3×3×3)
- **Total sounds**: 14
- **Sounds per combination**: 1-3 (average 1.6)
- **Coverage**: 100% - all combinations mapped, all sounds used
- **Most used sounds**: addon-complete (9 combos), research-complete (8 combos)
- **Most specific sounds**: abandoning-auxiliary-structure (destructive only), base-is-under-attack (questions only)

## Migration from v1.0

The old system used:
- severity (error/warning/success)
- magnitude (major/normal/minor)
- context (destructive/constructive/neutral)

The new system uses:
- mode (question/action/report)
- type (constructive/destructive/analytical)
- outcome (success/problem/neutral)

**Key improvements**:
1. "question" is now its own mode (was lumped into "warning" before)
2. "analytical" work (reading/searching) is distinct from constructive/destructive
3. "action" vs "report" clarifies whether work is in-progress or completed
4. More intuitive dimension names that match how we think about Claude's responses

## Validation

Run `validate-sound-map.sh` to verify:
- All 27 combinations are covered
- All 14 sounds are used at least once
- JSON structure is valid
- Sound files exist on disk

## Implementation

The system is used by `starcraft-sound-router-ai.sh` which:
1. Extracts the latest Claude Code response
2. Sends it to Claude Haiku API for classification
3. Gets back `{mode, type, outcome}`
4. Looks up sounds in `starcraft-sound-map-new.json`
5. Randomly selects one if multiple options
6. Plays the sound via `afplay`
