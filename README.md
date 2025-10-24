# 🎮 StarCraft Sound Effects for Claude Code

**"Nuclear launch detected!"** - Transform your AI coding assistant into a StarCraft Terran Adjutant with semantic audio feedback.

Ever wished you could instantly *hear* what type of response Claude just gave you? Now you can! This system maps Claude's responses to 14 iconic StarCraft: Brood War sounds based on their semantic meaning.

## 🔊 What You'll Hear

| Sound | When You'll Hear It | Example Response |
|-------|-------------------|------------------|
| **"Not enough minerals"** | Claude needs clarification | "Which file did you mean?" |
| **"Insufficient vespene gas"** | Claude needs resources | "Please provide the API key" |
| **"Your base is under attack"** | Problems found in your code | "Found 3 bugs in your implementation" |
| **"Nuclear missile ready"** | Major success! | "All tests passing! Deploy ready!" |
| **"Nuclear launch detected"** | Critical failure | "PRODUCTION IS DOWN!" |
| **"Research complete"** | Discovery/analysis done | "Found the root cause" |

...and 8 more semantic mappings that make your coding session feel like commanding a Terran base!

## 🚀 Quick Start

### Prerequisites

1. **Claude Code** (Anthropic's official Claude desktop app)
2. **macOS** (uses `afplay` for audio - Linux/Windows support coming soon)
3. **StarCraft sound files** (see [Getting Sounds](#getting-sounds) section)
4. **Anthropic API Key** (for AI classification)

### Installation

1. Clone this repository:
```bash
git clone https://github.com/Elijas/starcraft-sound-effects-for-claude-code.git
cd starcraft-sound-effects-for-claude-code
```

2. Set up your environment:
```bash
# Create .env file with your API key
echo "ANTHROPIC_API_KEY=your-api-key-here" > .env
```

3. Get the StarCraft sounds (see [Getting Sounds](#getting-sounds) section)

4. Configure Claude Code:
```bash
# Update Claude settings to use this system
# Add to ~/.claude/settings.json:
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "/path/to/starcraft-sound-effects-for-claude-code/starcraft-sound-router-v3.sh"
      }]
    }]
  }
}
```

5. Validate your setup:
```bash
./validate-sound-map-v3.sh
```

## 🎵 Getting Sounds

1. **Search online for**: "StarCraft unit sounds zip"
2. **You need these 14 files**:
   - `tadErr00-not-enough-minerals.wav`
   - `tadErr01-insufficient-vespene-gas.wav`
   - `tadErr02-additional-supply-depots-required.wav`
   - `TAdErr06-not-enough-energy.wav`
   - `tadUpd03-addon-complete.wav`
   - `tadUPD06-upgrade-complete.wav`
   - `tadUpd02-research-complete.wav`
   - `tadUPD05-abandoning-auxiliary-structure.wav`
   - `TAdUpd07-nuclear-missile-ready.wav`
   - `tadErr03-landing-sequence-interrupted.wav`
   - `tadUpd00-base-is-under-attack.wav`
   - `tadUpd01-your-forces-are-under-attack.wav`
   - `tadUPD04-nuclear-launch-detected.wav`
   - `tadErr04-unacceptable-landing-zone.wav`

3. **Place them in**: `/Users/[username]/Music/StarCraft/Starcraft1/Terran/Advisor-Annotated/`

   Or update the path in `starcraft-sounds.json` to your location.

## 🧠 How It Works

### The 14 Semantic Classes

The system uses AI to classify Claude's responses into 14 semantic categories:

| ID | Class | Sound | Meaning |
|----|-------|-------|---------|
| 1 | Need clarification | Not enough minerals | Ambiguous request |
| 2 | Need resources | Insufficient vespene gas | Missing files/access |
| 3 | Need selection | Additional supply depots required | Multiple options |
| 4 | Cannot locate | Not enough energy | Search failed |
| 5 | Routine complete | Addon complete | Small task done |
| 6 | Milestone complete | Upgrade complete | Major task done |
| 7 | Discovery complete | Research complete | Found/analyzed |
| 8 | Removal complete | Abandoning auxiliary structure | Deleted/cleaned |
| 9 | Optimal achievement | Nuclear missile ready | Exceptional success |
| 10 | Partial completion | Landing sequence interrupted | Mostly done |
| 11 | Problems discovered | Your base is under attack | Found issues |
| 12 | Operation failing | Your forces are under attack | Current errors |
| 13 | Critical failure | Nuclear launch detected | Emergency |
| 14 | Request impossible | Unacceptable landing zone | Cannot do |

### Technical Architecture

1. **Hook Integration**: Integrates with Claude Code's `assistant-response-stop` hook
2. **AI Classification**: Uses Claude Haiku API to classify responses (token-efficient prompt)
3. **Sound Playback**: Maps classification to sound file and plays via `afplay`
4. **Fallback**: Defaults to "addon complete" if classification fails

### Performance

- **API Cost**: ~0.001¢ per classification (uses Claude Haiku with minimal tokens)
- **Latency**: < 500ms typical (API call + sound playback)
- **Reliability**: Falls back gracefully if API is unavailable

## 📁 Repository Structure

```
starcraft-sound-effects-for-claude-code/
├── README.md                        # This file
├── SOUND-MAPPING-SYSTEM.md          # Detailed documentation
├── starcraft-sounds.json            # Sound mappings configuration
├── starcraft-sound-router-v3.sh     # Main router script
├── validate-sound-map-v3.sh         # Setup validator
├── .env                             # API key (create this)
├── .gitignore                       # Excludes .env and sounds
└── _old_versions/                   # Previous iterations for reference
    ├── claude-starcraft/            # v1/v2 implementation
    └── test scripts                 # Testing utilities
```

## 🛠️ Configuration

### Custom Sound Directory

Edit `starcraft-sounds.json`:
```json
{
  "sound_directory": "/your/custom/path/to/sounds"
}
```

### Adjust Classification Sensitivity

The system uses temperature 0.3 for consistent classification. Adjust in `starcraft-sound-router-v3.sh` if needed.

### Logging

All activity is logged to `router.log` for debugging.

## 🐛 Troubleshooting

### No Sound Playing
1. Check `router.log` for errors
2. Verify sound files exist: `./validate-sound-map-v3.sh`
3. Test audio: `afplay /path/to/any/sound.wav`

### Wrong Classifications
- The AI might misclassify edge cases
- Check `router.log` to see what class was assigned
- Falls back to class 5 (addon complete) if unsure

### API Issues
- Verify `ANTHROPIC_API_KEY` in `.env`
- Check API quota at console.anthropic.com
- System works without API (defaults to class 5)

## 🎮 Why StarCraft?

The StarCraft Terran Adjutant is the perfect metaphor:
- She was literally an AI assistant in the game
- The sounds have perfect emotional weight (urgent, routine, success, failure)
- Instant nostalgia hit for millions of players
- The sounds are already designed to convey information quickly

## 🚧 Roadmap

- [ ] Linux support (use `aplay` instead of `afplay`)
- [ ] Windows support (use PowerShell audio)
- [ ] VS Code extension version
- [ ] Cursor integration
- [ ] Volume control based on severity
- [ ] Custom sound packs (Zerg/Protoss advisors?)
- [ ] Statistics dashboard

## 📄 License

MIT License - See [LICENSE](LICENSE) file

**Note**: StarCraft sounds are property of Blizzard Entertainment. This project is a fan creation for personal use.

## 🙏 Credits

- Blizzard Entertainment for the iconic StarCraft sounds
- Anthropic for Claude and the classification API
- The StarCraft community for keeping the dream alive

## ⭐ Star History

If this made your coding sessions more epic, drop a star!

---

*"You must construct additional pylons"* - Wrong race, but you get the idea. Happy coding, Commander! 🚀
