# 🎮 StarCraft Sound Effects for Claude Code

**"Nuclear launch detected!"** - Transform your AI coding assistant into a StarCraft Terran Adjutant with semantic audio feedback.

Ever wished you could instantly *hear* what happened in Claude Code? Now you can. This system uses three StarCraft: Brood War Terran Adjutant audio channels: a 13-class semantic classifier, deterministic authorization prompts, and a once-per-session context-pressure alert.

## 🔊 What You'll Hear

A taste — the full 14-sound map lives in [The Sound Map](#the-sound-map):

| You hear | It means |
|----------|----------|
| **"Not enough minerals"** | Claude needs information from you |
| **"Insufficient vespene gas"** | Your authorization is needed |
| **"Nuclear missile ready"** | Shipped — push, publish, deploy |
| **"Nuclear launch detected"** | Catastrophe — drop everything |

Frequent sounds are calm; rare sounds are alarming. If you hear a sound you don't recognize, something unusual happened.

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
    }],
    "Notification": [{
      "matcher": "permission_prompt",
      "hooks": [{
        "type": "command",
        "command": "/path/to/notification-hook.sh",
        "timeout": 5
      }]
    }],
    "PreToolUse": [{
      "matcher": "ExitPlanMode",
      "hooks": [{
        "type": "command",
        "command": "/path/to/notification-hook.sh",
        "timeout": 5
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

### The Three Audio Channels

v4 separates deterministic events from semantic classification:

| Channel | Hook | Trigger | Sound |
|---------|------|---------|-------|
| Classifier | `Stop` | Claude's final assistant message is classified into one of 13 semantic outcomes | Class-specific sound below |
| Authorization | `Notification` + `PreToolUse` | Permission prompts and `ExitPlanMode` plan approvals | Insufficient vespene gas |
| Context pressure | `Stop` | Last usage record crosses `STARCRAFT_CONTEXT_LIMIT_TOKENS` (default `800000`) | Additional supply depots required |

The context-pressure default is `800000`, which is 80% of a 1M-token window. Override it with `STARCRAFT_CONTEXT_LIMIT_TOKENS`; for example, use `160000` for 200k-window models.

The classifier uses Claude Haiku at `temperature: 0`. If the classifier cannot run, returns an API error, or produces an invalid class, the classifier channel is silent by design. It will not play a fake fallback outcome.

### The Sound Map

The `Stop` hook classifies Claude's final response into 13 semantic classes (IDs match
`sound-config.json` and `router.log`). Shares are the measured distribution from the
author's real sessions — yours will differ, but the shape is the point: routine outcomes
got calm sounds, trouble got alarms.

| ID | You hear | It means | Example | ≈ Share |
|----|----------|----------|---------|---------|
| 1 | **"Not enough minerals"** | Needs info — asks what/which/how, missing facts | "Which file should I update?" | ~20% |
| 2 | **"Insufficient vespene gas"** | Needs plan approval before starting | "Approve this plan and I'll start." | ~13% |
| 3 | **"Not enough energy"** | Chunk done — continue or stop? | "First module done. Continue with the next?" | ~16% |
| 4 | **"Landing sequence interrupted"** | Working — status/ack, nothing finished yet | "I'm checking the failing tests now." | ~21% |
| 5 | **"Add-on complete"** | Milestone — sub-tasks landed, work continues | "Committed modules A and B; starting C now." | ~9% |
| 6 | **"Abandoning auxiliary structure"** | Wrapped up / parked — checkpoint, handoff, retiring | "Pausing here — clean checkpoint, nothing in flight." | ~5% |
| 7 | **"Research complete"** | Knowledge deliverable — analysis, report, docs, plan | "The root cause is in the parser." | ~12% |
| 8 | **"Upgrade complete"** | Code change complete (incl. deletions; local commits stay here) | "Implemented the fix and tests pass." | rare |
| 9 | **"Nuclear missile ready"** | Shipped — push, publish, release, merge, deploy | "Pushed the branch and opened the PR." | ~2% |
| 10 | **"Unacceptable landing zone"** | Cannot proceed — refused, impossible, or hard error | "API Error: rate limited." | ~2.5% |
| 11 | **"Your forces are under attack"** | Turn ends with new work failing | "The new test is still failing." | rare (bad news) |
| 12 | **"Your base is under attack"** | Regression — previously-working behavior broke | "12 previously-passing tests now fail." | rare (worse news) |
| 13 | **"Nuclear launch detected"** | Catastrophe — repo/env corrupt, destructive incident | "I force-pushed over your commits." | very rare (drop everything) |

Two more sounds fire from deterministic hooks (no classifier involved):

| You hear | It means | Fires |
|----------|----------|-------|
| **"Insufficient vespene gas"** | Blocked awaiting your permission or plan approval | On every permission dialog / `ExitPlanMode` |
| **"Additional supply depots required"** | Context crossed the threshold (default 800k tokens) | Once per session |

Class 2 and the authorization channel intentionally share **"Insufficient vespene gas"**: gas means your authorization is needed, regardless of whether the signal came from the classifier or hook metadata.

### Design Rationale

The v4.2 taxonomy was rebalanced against 200 real transcripts to spread firing rates: the top class is ~21%, and Gini improved to 0.55 from 0.67. Trouble classes are intentionally rare, while authorization and context pressure remain deterministic channels because they are better detected from hook metadata and transcript usage than from semantic classification.

### Technical Architecture

1. **Hook Integration**: Uses `Stop` for classifier/context pressure and `Notification` + `PreToolUse` for authorization prompts.
2. **AI Classification**: Uses Claude Haiku to classify responses. The model is **self-healing** — if the pinned Haiku model is retired (the API returns a `not_found` error), the router queries the API's model list, picks the newest Haiku by release date, and caches it in `.haiku-model` so future sessions skip the discovery.
3. **Deterministic Channels**: Permission prompts and high context usage are handled without AI classification.
4. **Sound Playback**: Maps configured outcomes to relative sound paths and plays via `afplay`.
5. **Presence gates**: The classifier stays quiet for background/subagent work; authorization prompts can also fire from detached sessions when a user is present at the machine (see [When Sounds Play](#when-sounds-play)).
6. **Logging**: Disabled by default (set `ENABLE_LOGGING=true` in script to enable).

> [!WARNING]
> **Real-Time Error Detection Currently Not Available**
>
> This project includes an `error-detection-hook.sh` that *should* play sounds immediately when tool errors occur (using `PostToolUse` hooks). However, due to a [known bug in Claude Code](https://github.com/anthropics/claude-code/issues/6403), **PostToolUse hooks fail to register** across multiple versions (1.0.89 - 2.0.31+).
>
> **Current Status:**
> - ✅ **Semantic classification works** (uses `Stop` hook - runs after Claude finishes)
> - ✅ **Authorization and context-pressure sounds work** (deterministic v4 channels)
> - ❌ **Real-time error detection broken** (uses `PostToolUse` hook - never registers)
>
> **Related Issues:**
> - [#6403 - PostToolUse Hooks Not Executing](https://github.com/anthropics/claude-code/issues/6403)
> - [#6305 - Post/PreToolUse Hooks Not Executing](https://github.com/anthropics/claude-code/issues/6305)
>
> The error detection code is ready and tested - it will work once Anthropic fixes the hook registration bug. Until then, v4 provides Stop-hook classification plus deterministic authorization and context-pressure sounds.

### Performance

- **API Cost**: ~0.001¢ per classification (uses Claude Haiku with minimal tokens)
- **Latency**: < 500ms typical (API call + sound playback)
- **Reliability**: Fails explicitly if `.env` is not configured; classifier API failures are silent by design so they never masquerade as a semantic outcome.

## 📁 Repository Structure

```
starcraft-sound-effects-for-claude-code/
├── README.md                       # This file
├── ERROR-DETECTION-README.md       # Error detection hook documentation
├── sound-config.json               # Centralized sound mappings (relative paths)
├── starcraft-sound-router.sh       # Semantic classification hook (AI)
├── notification-hook.sh            # Authorization prompt hook
├── error-detection-hook.sh         # Error detection hook (algorithmic)
├── setup.sh                        # Interactive setup script
├── test-hooks-offline.sh           # Offline hook wiring test with fake curl/afplay
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
  "authorization_sound": "Starcraft1/Terran/Advisor-Annotated/tadErr01-insufficient-vespene-gas.wav",
  "context_pressure_sound": "Starcraft1/Terran/Advisor-Annotated/tadErr02-additional-supply-depots-required.wav",
  "error_sound": "Starcraft1/Misc/PPwrDown.wav"
}
```

All sound paths are **relative to `STARCRAFT_ROOT_DIR`**, making the configuration:
- ✅ Portable across machines
- ✅ Private (user paths in gitignored .env)
- ✅ Maintainable (one config file)
- ✅ Extensible (easy to add new sounds)

**Layer 3: User Preferences (`~/.config/starcraft-sounds.yaml`)** — *optional*

Per-channel volume control. Every channel has its own key, and each is independent:

```yaml
completion:
  mode: default        # default (LLM router) | single | silent
error:
  mode: default        # default (pattern match) | single | silent
idle_warning:
  enabled: true
authorization:
  mode: default        # default (follow global toggle) | silent | always
```

`authorization` governs permission prompts and plan-approval dialogs:

| Value | Behaviour |
|---|---|
| `default` (or key absent) | Follows the global toggle — see below |
| `silent` | Permission prompts never make a sound |
| `always` | Permission prompts stay audible even when everything else is silenced |

**The global toggle.** There is no single `enabled:` flag. Sounds count as globally
OFF when `completion.mode` and `error.mode` are both `silent` **and**
`idle_warning.enabled` is `false`. That is precisely how the `starcraft` toggle
utility represents its own OFF state, so the two agree by construction.

**This file is entirely optional.** If it is missing — or if `yq` is not
installed — every channel falls back to its default and sounds play as normal.
Nothing here is required to run the project.

> Override the location with `STARCRAFT_USER_CONFIG=/path/to/config.yaml`.

### When Sounds Play

By default, classifier sounds play only in the **session you are actively watching**. This keeps a fleet of background or parallel sessions from turning into a chorus.

The `Stop` classifier/context hook decides in this order:

1. **`STARCRAFT_SOUNDS` override** (environment variable) — controls primary-session playback:
   - `STARCRAFT_SOUNDS=1` (or `on` / `true`) → always play
   - `STARCRAFT_SOUNDS=0` (or `off` / `false`) → always silent
2. **Subagents stay silent** — in-process subagents (`SubagentStop`) never play.
3. **Auto (no override):**
   - **Not in tmux** (plain terminal) → **play**. This is the default for most users.
   - **In tmux, session attached** (a client is viewing it) → **play**.
   - **In tmux, session detached** (running in the background) → **silent**.

**No special tooling required.** The only optional dependency is `tmux`, and it is consulted *only* when you are already inside a tmux session. If you don't use tmux, sounds simply play on every response.

> Because the attached-check is evaluated live on every response, a background tmux session brought to the foreground starts playing on its next response (no restart needed), and a foreground session sent to the background goes quiet.

The authorization hook uses a presence-aware variant because permission prompts may happen in detached sessions:

1. **`STARCRAFT_SOUNDS` override** — as above; `1`/`on` forces play, `0`/`off` forces silence.
2. **User config gate** (`~/.config/starcraft-sounds.yaml`, optional):
   - `authorization.mode: silent` → never play permission prompts.
   - `authorization.mode: always` → stay audible even when the global toggle is off.
   - `default` or absent → follow the global toggle (silent only when completion **and** error are `silent` **and** idle warnings are off).
   - No config file, or no `yq` → play, exactly as before this gate existed.
3. Not in tmux → play.
4. In tmux and this session is attached → play.
5. In tmux and this session is detached → play only if `tmux list-clients` shows a user is currently at the machine.
6. Detached prompts are debounced per session for 10 minutes so overnight fleets do not repeatedly alert.

> Before this gate existed, silencing every other channel still left permission
> prompts audible, because authorization was the one channel with no config key
> of its own.

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
2. Verify sound files exist under `STARCRAFT_ROOT_DIR`
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
- Classifier API errors are logged and silent by design; authorization/context sounds do not require classifier API calls

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
