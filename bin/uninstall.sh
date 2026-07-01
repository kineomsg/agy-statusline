#!/bin/bash
set -e

STATUSLINE_DEST="$HOME/.gemini/statusline.sh"
STATUSLINE_BACKUP="${STATUSLINE_DEST}.bak"
SETTINGS_FILE="$HOME/.gemini/antigravity-cli/settings.json"

C_RESET=$'\e[0m'
C_PURPLE=$'\e[38;2;167;139;250m'
C_GREEN=$'\e[38;2;130;180;100m'
C_AMBER=$'\e[38;2;229;192;123m'
C_DIM=$'\e[38;2;92;99;112m'

ok()   { echo -e "  ${C_GREEN}✓${C_RESET} $1"; }
warn() { echo -e "  ${C_AMBER}!${C_RESET} $1"; }

echo
echo -e "  ${C_PURPLE}agy-statusline uninstaller${C_RESET}"
echo -e "  ${C_DIM}──────────────────────────${C_RESET}"
echo

if [ -f "$STATUSLINE_BACKUP" ]; then
    cp "$STATUSLINE_BACKUP" "$STATUSLINE_DEST"
    rm "$STATUSLINE_BACKUP"
    ok "Restored previous statusline from backup"
elif [ -f "$STATUSLINE_DEST" ]; then
    rm "$STATUSLINE_DEST"
    ok "Removed ${C_DIM}statusline.sh${C_RESET}"
else
    warn "No statusline found — nothing to remove"
fi

if [ -f "$SETTINGS_FILE" ]; then
    tmp=$(mktemp)
    jq 'del(.statusLine)' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    ok "Removed statusLine from ${C_DIM}settings.json${C_RESET}"
fi

echo
echo -e "  ${C_GREEN}Done!${C_RESET} Restart agy to apply changes."
echo
