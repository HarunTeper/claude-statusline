# claude-statusline

A statusline script for [Claude Code](https://claude.ai/code) that displays model, git branch, context usage, session cost, and rolling rate limit progress bars.

## What it shows

```
Sonnet 4.6 (plan)  main  ctx:19% (38k/200k)  $0.88  5h:[█░░░░░░░░░] 13%  ↺ 14:32 (3h26m)  7d:[██░░░░░░░░] 20%  ↺ 22:14 (80h26m)
```

- **Model** — display name of the active model, with effort/mode in parentheses when applicable (e.g. `plan`, `fast`)
- **Git branch** — current branch of the workspace
- **ctx%** — context window usage percentage and token count (`used/total`)
- **$X.XX** — session cost so far
- **5h bar** — 5-hour rolling rate limit usage with reset time and countdown
- **7d bar** — 7-day rolling rate limit usage with reset time and countdown

Colors go green → yellow → red as usage crosses 50% and 80%.

## Requirements

- `jq` — `sudo apt-get install jq` / `brew install jq`
- `git`
- `awk` (standard on all platforms)

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
