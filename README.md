# claude-statusline

A statusline script for [Claude Code](https://claude.ai/code) that displays model, git branch, context usage, session cost, and rolling rate limit progress bars.

## What it shows

```
Sonnet 4.6  main  ctx:19%  $0.88  5h:[█░░░░░░░░░] 13%  ↺ 3h26m  7d:[██░░░░░░░░] 20%  ↺ 80h26m
```

- **Model** — display name of the active model
- **Git branch** — current branch of the workspace
- **ctx%** — context window usage percentage
- **$X.XX** — session cost so far
- **5h bar** — 5-hour rolling rate limit usage with reset timer
- **7d bar** — 7-day rolling rate limit usage with reset timer

Colors go green → yellow → red as usage crosses 50% and 80%.

## Requirements

- `jq` — `sudo apt-get install jq` / `brew install jq`
- `git`

## Installation

1. Copy `statusline-command.sh` to `~/.claude/statusline-command.sh`
2. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

That's it — Claude Code picks it up immediately.
