#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/statusline-command.sh"
SETTINGS="$HOME/.claude/settings.json"

# Copy the script
mkdir -p "$HOME/.claude"

# Detect process substitution (bash <(...)), where BASH_SOURCE[0] is /dev/fd/N
if [[ "$SCRIPT_DIR" == /dev/fd* || "$SCRIPT_DIR" == /proc/self/fd* ]]; then
    echo "Error: install.sh must be run from a local clone, not via process substitution."
    echo "Run: git clone https://github.com/HarunTeper/claude-statusline && cd claude-statusline && bash install.sh"
    exit 1
fi

cp "$SCRIPT_DIR/statusline-command.sh" "$DEST"
chmod +x "$DEST"
echo "Installed: $DEST"

# Patch settings.json
if [ ! -f "$SETTINGS" ]; then
    echo '{}' > "$SETTINGS"
fi

if command -v jq &>/dev/null; then
    tmp=$(mktemp)
    jq '.statusLine = {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}' "$SETTINGS" > "$tmp"
    mv "$tmp" "$SETTINGS"
    echo "Updated: $SETTINGS"
else
    echo ""
    echo "jq not found — add this to $SETTINGS manually:"
    echo '  "statusLine": {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}'
fi

echo "Done. Restart Claude Code to see the statusline."
