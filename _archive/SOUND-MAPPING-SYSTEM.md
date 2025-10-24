# StarCraft Sound Mapping System v3

## Overview

This system provides semantic audio feedback for AI assistant responses using 14 iconic StarCraft: Brood War Terran Adjutant sounds. Each sound maps to a specific semantic class, giving instant audio understanding of what type of response was received.

## The 14-Class Semantic Mapping

| ID | Sound File | Semantic Class | When It Triggers | Example Responses |
|----|------------|----------------|-------------------|-------------------|
| 1 | `tadErr00-not-enough-minerals.wav` | **Need clarification** | Ambiguous request requires resolution | "Should I use React or Vue for this?", "Which file did you mean?", "Do you want JSON or CSV format?" |
| 2 | `tadErr01-insufficient-vespene-gas.wav` | **Need resources** | Missing required materials or access | "I need the API key to proceed", "Please provide the dataset file", "Can't access that directory without permissions" |
| 3 | `tadErr02-additional-supply-depots-required.wav` | **Need selection** | Multiple valid paths available | "Choose an approach: (A) Fast but risky (B) Safe but slow (C) Balanced", "Which option would you prefer?" |
| 4 | `TAdErr06-not-enough-energy.wav` | **Cannot locate** | Search or lookup unsuccessful | "No files match that pattern", "Function not found in codebase", "Can't find that reference" |
| 5 | `tadUpd03-addon-complete.wav` | **Routine complete** | Small incremental progress made | "File saved", "Variable renamed", "Comment added to function" |
| 6 | `tadUPD06-upgrade-complete.wav` | **Milestone complete** | Significant task accomplished | "Feature fully implemented", "All tests passing", "Analysis complete with results" |
| 7 | `tadUpd02-research-complete.wav` | **Discovery complete** | Information found or analyzed | "Found the root cause", "Pattern identified in data", "Located 15 matching files" |
| 8 | `tadUPD05-abandoning-auxiliary-structure.wav` | **Removal complete** | Elimination or cleanup performed | "Old files deleted", "Cache cleared successfully", "Removed deprecated code" |
| 9 | `TAdUpd07-nuclear-missile-ready.wav` | **Optimal achievement** | Best possible result achieved | "PERFECT SCORE - 100% test coverage!", "Zero errors, deployment successful!", "All objectives exceeded!" |
| 10 | `tadErr03-landing-sequence-interrupted.wav` | **Partial completion** | Incomplete but acceptable result | "Completed 8 of 10 tasks", "Tests pass but warnings remain", "Saved locally but couldn't push to remote" |
| 11 | `tadUpd00-base-is-under-attack.wav` | **Problems discovered** | Pre-existing issues detected | "Found 3 bugs in your code", "Security vulnerabilities detected", "Data inconsistencies identified" |
| 12 | `tadUpd01-your-forces-are-under-attack.wav` | **Operation failing** | Current actions causing problems | "Build failing with errors!", "Tests breaking after changes!", "Connection lost during operation!" |
| 13 | `tadUPD04-nuclear-launch-detected.wav` | **Critical failure** | Emergency or severe situation | "PRODUCTION DOWN!", "Database corrupted!", "CRITICAL SECURITY BREACH!" |
| 14 | `tadErr04-unacceptable-landing-zone.wav` | **Request impossible** | Fundamental blocker exists | "Cannot modify system files", "That violates safety guidelines", "Mathematically impossible to achieve" |

## Design Philosophy

### Semantic Consistency
Each sound maintains its original StarCraft emotional weight while mapping to abstract semantic classes that work across all domains:
- **Mineral/gas sounds** → User needs to provide something
- **Complete sounds** → Various levels of task completion
- **Attack sounds** → Different severity of problems
- **Nuclear sounds** → Extreme events (very good or very bad)

### Frequency Distribution
The system ensures good variety during typical work sessions:
- **High frequency**: Classes 5-7 (routine work and discoveries)
- **Medium frequency**: Classes 1-3, 11-12 (clarifications and common problems)
- **Lower frequency**: Classes 9, 13-14 (extreme outcomes)
- **Balanced**: Classes 4, 8, 10 (specific situations)

### Abstract Classes
The semantic classes are domain-agnostic, working equally well for:
- Software development
- Data analysis
- Content creation
- Problem solving
- General conversation

## Integration

### Claude Code Hook Configuration

Add this to your Claude Code settings:

```json
{
  "assistant-response-stop": "/Users/user/bin/claude-starcraft-v3/starcraft-sound-router-v3.sh"
}
```

### Required Environment

1. **API Key**: Set `ANTHROPIC_API_KEY` in `.env` file
2. **Sound Files**: Located in `/Users/user/Music/StarCraft/Starcraft1/Terran/Advisor-Annotated/`
3. **macOS**: Uses `afplay` for audio playback

## Classification Prompt

The system uses this token-efficient prompt for Claude API:

```
Classify this AI assistant message into ONE of 14 classes:

1=Need clarification (ambiguous request)
2=Need resources (missing files/access)
3=Need selection (multiple options)
4=Cannot locate (search failed)
5=Routine complete (small task done)
6=Milestone complete (major task done)
7=Discovery complete (found/analyzed)
8=Removal complete (deleted/cleaned)
9=Optimal achievement (exceptional success)
10=Partial completion (mostly done)
11=Problems discovered (found issues)
12=Operation failing (current errors)
13=Critical failure (emergency)
14=Request impossible (cannot do)

Message: [ASSISTANT_MESSAGE]

Return ONLY: {"class": N}
```

## Technical Details

### Files

- `starcraft-sounds.json` - Maps class IDs to sound files
- `starcraft-sound-router-v3.sh` - Main router script
- `.env` - Contains ANTHROPIC_API_KEY
- `validate-sound-map-v3.sh` - Validates configuration

### API Configuration

- **Model**: `claude-3-haiku-20240307`
- **Max Tokens**: 20 (only needs to return a number)
- **Temperature**: 0.3 (consistent classification)

### Error Handling

- Falls back to class 5 (addon-complete) if API fails
- Logs all activity to `router.log`
- Continues silently on any errors

## Benefits Over Previous Versions

### v3 Improvements
- **50% smaller API prompt** - Reduced from ~500 to ~200 tokens
- **Direct classification** - Single number instead of 3D object
- **Cleaner codebase** - No legacy files or complex mappings
- **Better semantics** - Abstract classes work for any domain
- **Improved distribution** - All 14 sounds used regularly

### Performance
- **API Cost**: ~70% reduction due to smaller prompt
- **Response Time**: Faster with simpler classification
- **Reliability**: Number-based response more robust

## Validation

Run the validator to ensure your setup is correct:

```bash
./validate-sound-map-v3.sh
```

This checks:
- All 14 classes are mapped
- Sound files exist
- API key is configured
- No duplicate mappings

## Troubleshooting

### No Sound Playing
1. Check `router.log` for errors
2. Verify sound files exist in expected directory
3. Ensure `afplay` command works: `afplay /path/to/sound.wav`

### Wrong Classifications
1. Check API key is valid
2. Review recent messages in `router.log`
3. Manually test classification with sample messages

### API Errors
1. Verify ANTHROPIC_API_KEY in `.env`
2. Check API quota/rate limits
3. Falls back to default sound if API unavailable

## Future Enhancements

Potential improvements for v4:
- Support for multiple sound themes
- User-configurable class mappings
- Volume control based on severity
- Statistical tracking of class distribution
- Integration with other notification systems