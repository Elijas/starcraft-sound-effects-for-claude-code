# 🎮 StarCraft Sound Effects for Claude Code

**"Nuclear launch detected!"** - Transform your AI coding assistant into a StarCraft Terran Adjutant with semantic audio feedback.

Ever wished you could instantly *hear* what type of response Claude just gave you? Now you can! This system maps Claude's responses to 14 iconic StarCraft: Brood War sounds based on their semantic meaning.

## 🔊 What You'll Hear

| Sound | When You'll Hear It | Example Response |
|-------|-------------------|------------------|
| **"Not enough minerals"** | Claude needs clarification | "Which file did you mean?" |
| **"Insufficient vespene gas"** | Claude needs permissions | "Missing API key or credentials" |
| **"Your base is under attack"** | Problems found in your code | "Found 3 bugs in your implementation" |
| **"Nuclear missile ready"** | Major success! | "Git pushed! Tests passing! Deployed!" |
| **"Nuclear launch detected"** | System broken | "Can't compile! Repo corrupted!" |
| **"Research complete"** | Analysis done | "Found the root cause" |

...and 8 more semantic mappings that make your coding session feel like commanding a Terran base!

## 🚀 Quick Start

### Prerequisites

1. **Claude Code** (Anthropic's official Claude desktop app)
2. **macOS** (uses `afplay` for audio - Linux/Windows support coming soon)
3. **StarCraft sound files** (see [Getting Sounds](#getting-sounds) section)
4. **Anthropic API Key** ([Get one here](https://console.anthropic.com/))

### Installation

1. Clone this repository:
```bash
git clone https://github.com/Elijas/starcraft-sound-effects-for-claude-code.git
cd starcraft-sound-effects-for-claude-code
```

2. Run the setup script:
```bash
./setup.sh
```

This will:
- Create your `.env` file from template
- Configure your API key
- Set up your sound directory path
- Test the API connection
- Update Claude Code settings

That's it! Restart Claude Code and you're ready to go.

### Manual Setup

If you prefer manual configuration:

1. Copy the environment template:
```bash
cp .env.example .env
```

2. Edit `.env` with your settings:
```bash
ANTHROPIC_API_KEY=your-api-key-here
STARCRAFT_ROOT_DIR=/Users/your-username/Music/StarCraft
```

**Note**: The system uses **centralized configuration**:
- `STARCRAFT_ROOT_DIR` in `.env` (private, portable)
- `sound-config.json` for sound mappings (relative paths)

3. Update Claude settings (`~/.claude/settings.json`):
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Bash|BashOutput|Read|Write|Edit|Glob|Grep|WebFetch|WebSearch",
      "hooks": [{
        "type": "command",
        "command": "/path/to/error-detection-hook.sh",
        "timeout": 5
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "/path/to/starcraft-sound-router.sh"
      }]
    }]
  }
}
```

## 🎵 Getting Sounds

1. **Search online for**: "StarCraft Brood War Terran Advisor sounds"
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

3. **Place them in** the directory you specify in `.env`

## 🧠 How It Works

### The 14 Semantic Classes

The system uses AI to classify Claude's responses into 14 semantic categories:

| ID | Class | Sound | Meaning |
|----|-------|-------|---------|
| 1 | Need clarification | Not enough minerals | Ambiguous, need details |
| 2 | Need permissions | Insufficient vespene gas | Missing API key/credentials |
| 3 | Need user choice | Additional supply depots required | Multiple valid options |
| 4 | Search failed | Not enough energy | Couldn't find file/function |
| 5 | Simple edit done | Addon complete | Single file, minor change |
| 6 | Feature complete | Upgrade complete | Function/bug fix/refactor |
| 7 | Analysis complete | Research complete | Code explained/files read |
| 8 | Cleanup complete | Abandoning auxiliary structure | Deleted/removed code |
| 9 | Deployed successfully | Nuclear missile ready | Git push/tests pass/exploration sealed |
| 10 | Partially done | Landing sequence interrupted | Most complete, some remain |
| 11 | Issues found | Your base is under attack | Warnings/lint errors discovered |
| 12 | Tests failing | Your forces are under attack | Build/type/test errors |
| 13 | System broken | Nuclear launch detected | Can't compile/repo corrupt |
| 14 | Cannot proceed | Unacceptable landing zone | Impossible/out of scope |

### Technical Architecture

1. **Hook Integration**: Integrates with Claude Code's `Stop` hook
2. **AI Classification**: Uses Claude Haiku to classify responses. The model is **self-healing** — if the pinned Haiku model is retired (the API returns a `not_found` error), the router queries the API's model list, picks the newest Haiku by release date, and caches it in `.haiku-model` so future sessions skip the discovery.
3. **Sound Playback**: Maps classification to sound file and plays via `afplay`
4. **Foreground gate**: Only the session you're actively watching makes sound (see [When Sounds Play](#when-sounds-play)) — in-process subagents and background sessions stay silent
5. **Logging**: Disabled by default (set `ENABLE_LOGGING=true` in script to enable)

> [!WARNING]
> **Real-Time Error Detection Currently Not Available**
>
> This project includes an `error-detection-hook.sh` that *should* play sounds immediately when tool errors occur (using `PostToolUse` hooks). However, due to a [known bug in Claude Code](https://github.com/anthropics/claude-code/issues/6403), **PostToolUse hooks fail to register** across multiple versions (1.0.89 - 2.0.31+).
>
> **Current Status:**
> - ✅ **Semantic classification works** (uses `Stop` hook - runs after Claude finishes)
> - ❌ **Real-time error detection broken** (uses `PostToolUse` hook - never registers)
>
> **Related Issues:**
> - [#6403 - PostToolUse Hooks Not Executing](https://github.com/anthropics/claude-code/issues/6403)
> - [#6305 - Post/PreToolUse Hooks Not Executing](https://github.com/anthropics/claude-code/issues/6305)
>
> The error detection code is ready and tested - it will work once Anthropic fixes the hook registration bug. Until then, only the semantic classification (Stop hook) provides audio feedback.

### Performance

- **API Cost**: ~0.001¢ per classification (uses Claude Haiku with minimal tokens)
- **Latency**: < 500ms typical (API call + sound playback)
- **Reliability**: Fails explicitly if .env not configured (no silent failures)

## 📁 Repository Structure

```
starcraft-sound-effects-for-claude-code/
├── README.md                       # This file
├── ERROR-DETECTION-README.md       # Error detection hook documentation
├── sound-config.json               # Centralized sound mappings (relative paths)
├── starcraft-sound-router.sh       # Semantic classification hook (AI)
├── error-detection-hook.sh         # Error detection hook (algorithmic)
├── setup.sh                        # Interactive setup script
├── test-error-detection.sh         # Test error detection
├── test-semantic-sounds.sh         # Test semantic sounds
├── .env.example                    # Environment template
├── .env                            # Your configuration (git ignored)
├── .haiku-model                    # Cached Haiku model id, self-healed (git ignored)
├── .gitignore                      # Excludes .env and sounds
└── _archive/                       # Old versions and docs
```

## 🛠️ Configuration

### Centralized Configuration System

The system uses a **two-layer configuration** for portability and maintainability:

**Layer 1: Private Paths (`.env`)**
```bash
ANTHROPIC_API_KEY=sk-ant-api03-...     # Your API key
STARCRAFT_ROOT_DIR=/Users/you/Music/StarCraft  # Private, portable root directory
```

**Layer 2: Sound Mappings (`sound-config.json`)**
```json
{
  "semantic_sounds": {
    "1": "Starcraft1/Terran/Advisor-Annotated/tadErr00-not-enough-minerals.wav",
    ...
  },
  "error_sound": "Starcraft1/Misc/PPwrDown.wav"
}
```

All sound paths are **relative to `STARCRAFT_ROOT_DIR`**, making the configuration:
- ✅ Portable across machines
- ✅ Private (user paths in gitignored .env)
- ✅ Maintainable (one config file)
- ✅ Extensible (easy to add new sounds)

### When Sounds Play

By default, sound plays only in the **session you are actively watching**. This keeps a fleet of background or parallel sessions from turning into a chorus.

The `Stop` hook decides in this order:

1. **`STARCRAFT_SOUNDS` override** (environment variable) — always wins:
   - `STARCRAFT_SOUNDS=1` (or `on` / `true`) → always play
   - `STARCRAFT_SOUNDS=0` (or `off` / `false`) → always silent
2. **Subagents stay silent** — in-process subagents (`SubagentStop`) never play.
3. **Auto (no override):**
   - **Not in tmux** (plain terminal) → **play**. This is the default for most users.
   - **In tmux, session attached** (a client is viewing it) → **play**.
   - **In tmux, session detached** (running in the background) → **silent**.

**No special tooling required.** The only optional dependency is `tmux`, and it is consulted *only* when you are already inside a tmux session. If you don't use tmux, sounds simply play on every response.

> Because the attached-check is evaluated live on every response, a background tmux session brought to the foreground starts playing on its next response (no restart needed), and a foreground session sent to the background goes quiet.

### Logging

Logging is disabled by default. To enable, edit `starcraft-sound-router.sh`:
```bash
ENABLE_LOGGING=true  # Set to true to enable logging
```

Logs are written to `router.log`.

## 🐛 Troubleshooting

### No Sound Playing at All

**Most Common Issue: Workspace Trust Not Accepted**

Claude Code requires you to trust a workspace before hooks can run. If you don't trust the workspace, hooks are silently disabled for security.

**How to fix:**
1. Exit Claude Code completely
2. Navigate to your project directory:
   ```bash
   cd /path/to/starcraft-sound-effects-for-claude-code
   ```
3. Start Claude Code:
   ```bash
   claude-code
   ```
4. **Look for a workspace trust prompt** when Claude Code starts
5. **Accept/Trust the workspace**

**How to verify it's working:**
- Check debug logs: `grep "Stop hook" ~/.claude/debug/latest`
- If you see `"Skipping Stop hook execution - workspace trust not accepted"`, the workspace is not trusted
- After trusting, you should see hook execution in the logs

**Other sound issues:**
1. Check if `.env` exists and is configured
2. Verify sound files exist in `SOUND_DIR`
3. Test audio manually: `afplay /path/to/any/sound.wav`
4. Enable logging in the script (set `ENABLE_LOGGING=true`)
5. Check logs: `tail -20 router.log`

### Wrong Classifications
- The AI might misclassify edge cases
- Enable logging to see what class was assigned
- System is designed to handle all response types

### API Issues
- Verify `ANTHROPIC_API_KEY` in `.env`
- Check API quota at console.anthropic.com
- Run `./setup.sh` to test API connection

## 🎮 Why StarCraft?

The StarCraft Terran Adjutant is the perfect metaphor:
- She was literally an AI assistant in the game
- The sounds have perfect emotional weight (urgent, routine, success, failure)
- Instant nostalgia hit for millions of players
- The sounds are already designed to convey information quickly

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
