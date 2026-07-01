#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGY_DIR="$HOME/.gemini/antigravity-cli"
SETTINGS_FILE="$AGY_DIR/settings.json"
STATUSLINE_DEST="$HOME/.gemini/statusline.sh"
STATUSLINE_SRC="$SCRIPT_DIR/statusline.sh"

C_RESET=$'\e[0m'
C_PURPLE=$'\e[38;2;167;139;250m'
C_GREEN=$'\e[38;2;130;180;100m'
C_RED=$'\e[38;2;224;108;117m'
C_AMBER=$'\e[38;2;229;192;123m'
C_DIM=$'\e[38;2;92;99;112m'

ok()   { echo -e "  ${C_GREEN}✓${C_RESET} $1"; }
warn() { echo -e "  ${C_AMBER}!${C_RESET} $1"; }
fail() { echo -e "  ${C_RED}✗${C_RESET} $1"; exit 1; }

echo
echo -e "  ${C_PURPLE}agy-statusline installer${C_RESET}"
echo -e "  ${C_DIM}────────────────────────${C_RESET}"
echo

for dep in jq git; do
    command -v "$dep" >/dev/null 2>&1 || fail "Missing dependency: $dep — install it and retry"
done
ok "Dependencies found (jq, git)"

[ -d "$AGY_DIR" ] || fail "Antigravity CLI config not found at $AGY_DIR — is agy installed?"
ok "Found agy config at ${C_DIM}$AGY_DIR${C_RESET}"

if [ -f "$STATUSLINE_DEST" ]; then
    cp "$STATUSLINE_DEST" "${STATUSLINE_DEST}.bak"
    warn "Backed up existing statusline to ${C_DIM}statusline.sh.bak${C_RESET}"
fi

cp "$STATUSLINE_SRC" "$STATUSLINE_DEST"
chmod +x "$STATUSLINE_DEST"
ok "Installed statusline to ${C_DIM}$STATUSLINE_DEST${C_RESET}"

[ -f "$SETTINGS_FILE" ] || echo '{}' > "$SETTINGS_FILE"

STATUS_CMD='bash "$HOME/.gemini/statusline.sh"'
CURRENT_CMD=$(jq -r '.statusLine.command // ""' "$SETTINGS_FILE" 2>/dev/null)

if [ "$CURRENT_CMD" = "$STATUS_CMD" ]; then
    ok "settings.json already configured"
else
    tmp=$(mktemp -t 'agy-statusline.XXXXXX' 2>/dev/null || mktemp)
    trap 'rm -f "$tmp"' EXIT
    jq --arg cmd "$STATUS_CMD" \
        '.statusLine = {"type": "command", "command": $cmd, "enabled": true}' \
        "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    ok "Updated ${C_DIM}settings.json${C_RESET} with statusLine config"
fi

echo
echo -e "  ${C_GREEN}Done!${C_RESET} Restart agy to see your status line."
echo
