# agy-statusline

Status line for the **Antigravity CLI** (`agy`) — displays model name, session quota, and weekly quota with color-coded gauges.

```
Gemini3.5Flash(High) Session:▰▱▱▱▱27%(20:40) Week:▱▱▱▱▱16%(3d6h)
```

## What it shows

| Field | Description |
|---|---|
| Model name | Active model (`!!` prefix and red color for Sonnet, Opus, and Gemini Pro) |
| `Session:▰▱▱▱▱27%(20:40)` | 5-hour quota usage + reset time (HH:MM) |
| `Week:▱▱▱▱▱16%(3d6h)` | Weekly quota usage + time until reset |

Quota pool (`claude` / `gemini`) is auto-detected from the active model — no configuration needed.

**Gauge colors:**
- Green — under 60%
- Amber — 60–79%
- Red — 80%+

## Requirements

- [`jq`](https://jqlang.github.io/jq/)
- `git`
- `agy` (Antigravity CLI) installed

## Installation

```bash
git clone https://github.com/kineomsg/agy-statusline
cd agy-statusline
bash bin/install.sh
```

Restart `agy` to see the status line.

## Uninstall

```bash
bash bin/uninstall.sh
```

## How it works

`agy` runs the command configured under `statusLine` in `~/.gemini/antigravity-cli/settings.json`, passing the current session state as JSON via stdin on every prompt render. The script parses it and outputs ANSI-colored text — no tokens consumed.

```json
"statusLine": {
  "type": "command",
  "command": "bash \"$HOME/.gemini/statusline.sh\"",
  "enabled": true
}
```

Toggle on/off at any time with `/statusline` inside `agy`.

## Compatibility

- Linux (GNU date)
- macOS (BSD date)
