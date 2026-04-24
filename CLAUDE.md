# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single Bash script (`statusline-command.sh`) that Claude Code runs as a statusline command. It reads a JSON payload from stdin (provided by Claude Code via the `statusLine.command` hook) and prints a colored, human-readable status line.

## Testing

There is no test suite. To manually test the script, pipe a sample JSON payload:

```bash
echo '{"model":{"display_name":"Sonnet 4.6","reasoning_effort":null},"context_window":{"context_window_size":200000,"used_percentage":19.3},"rate_limits":{"five_hour":{"used_percentage":13,"resets_at":1714000000},"seven_day":{"used_percentage":20,"resets_at":1714500000}},"cost":{"total_cost_usd":0.88},"workspace":{"current_dir":"."}}' | bash statusline-command.sh
```

To test with `reasoning_effort` set (e.g. plan mode):

```bash
echo '{"model":{"display_name":"Opus 4.7","reasoning_effort":"plan"},...}' | bash statusline-command.sh
```

## Architecture

The script is entirely self-contained in `statusline-command.sh`:

1. **Input** — reads the full JSON from stdin into `$input` via `cat`
2. **Parsing** — extracts fields with `jq` (model, effort, context window, rate limits, cost, workspace dir)
3. **Effort/mode fallback** — if `reasoning_effort` is absent in the JSON, reads `~/.claude/settings.json` to detect `plan`/`fast` model suffixes
4. **Git branch** — runs `git rev-parse` against `workspace.current_dir` using `GIT_OPTIONAL_LOCKS=0` to avoid lock contention
5. **`make_bar PCT LABEL`** — renders a 10-cell block/░ bar with green/yellow/red coloring at 50%/80% thresholds
6. **`format_resets_at UNIX_TIMESTAMP`** — formats a reset time as `HH:MM (NhNNm)` countdown, cross-platform (GNU `date -d` with BSD `date -r` fallback)
7. **Output** — assembles ANSI-colored segments and writes with `printf '%b'`

## Keeping docs in sync

When changing the script's output format or adding new fields, update `README.md` — specifically the example output line and the bullet descriptions under "What it shows".

## Installation (for reference)

Copy the script to `~/.claude/statusline-command.sh` and add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

## Dependencies

- `jq` — JSON parsing
- `git` — branch detection
- `awk` — floating-point arithmetic (cost formatting, context token math)
- `date` — GNU (`-d @TS`) or BSD (`-r TS`) timestamp formatting
