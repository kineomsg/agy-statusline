# agy-statusline

Status line for the **Antigravity CLI** (`agy`) — displays model name, session quota, and weekly quota with color-coded gauges.

```
Gemini3.7Flash(High) Session:▰▱▱▱▱27%(20:40) Week:▱▱▱▱▱16%(3d6h)
```

## What it shows

| Field | Description |
|---|---|
| Model name | Active model (`!!` prefix and red color for Sonnet, Opus, and Gemini Pro) |
| `Session:▰▱▱▱▱27%(20:40)` | 5-hour quota usage + reset time (HH:MM) |
| `Week:▱▱▱▱▱16%(3d6h)` | Weekly quota usage + time until reset |

Quota pool (`claude` / `gemini`) is auto-detected from the active model — no configuration needed.

**Gauge colors:**
- The displayed percentage is always your raw usage, but the *color* also factors in pace: given how much of the 5-hour/weekly window has elapsed, will you exhaust the quota before it resets?
- A steady, constant rate of usage always lands close to 100% by definition when the window resets — that's normal, expected utilization. So the pace signal uses its own thresholds (green below 110% projected, amber 110-150%, red 150%+) rather than the raw 60%/80% thresholds.
- The raw usage thresholds (60%/80%) still apply independently — if your actual usage is already high late in the window, it shows red/amber regardless of pace.
- The final color is whichever of the two signals (raw usage or pace) is more severe.
- Pace is only considered once at least 5% of the window has elapsed, to avoid noisy projections right after a reset.

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

## Changelog

### 2026-08-23

Six confirmed bugs from a stealth/ox-alpha (OpenRouter) self-review, fixed and redeployed (commit `37ebd0e`):

- **Fixed**: `to_epoch()`'s macOS (`date -j`) fallback misinterpreted a naive UTC timestamp as local time, skewing reset-time displays by the local UTC offset. Fixed with a `TZ=UTC` prefix
- **Fixed**: `jq_fields2`'s `h5_pct`/`d7_pct` type checks used `!= null` instead of verifying the value is numeric, so a non-numeric quota field took the model name display down with it. Changed to `(type) == "number"` guards
- **Fixed**: unknown reset time displayed as `(soon)` instead of an explicit unknown-value indicator; changed to `?`. A follow-up fix was needed in `to_epoch()` itself, since GNU `date -d ""` doesn't error on an empty string (it silently returns today's midnight instead of failing), which prevented the intended empty-string branch from ever firing
- **Fixed**: `model_display` could carry raw ANSI escape codes through into the final output; now piped through the existing `strip_ansi()` helper first
- **Fixed**: `bin/install.sh` didn't back up `settings.json` before overwriting it, and its `jq ... && mv ...` pattern (not wrapped in an `if`) let a `jq` failure pass silently under bash's `set -e` AND-list exemption, reporting success even when the JSON update failed. Added a `.bak` backup and explicit `if`/`else` failure detection

## Known Limitations

- **Quota pool classification for `gpt-oss-*` models remains unverified**: Models matching `claude|anthropic|3p` are routed to the 3p quota keys (`3p-5h`/`3p-weekly`), while all other models default to the Gemini quota keys (`gemini-5h`/`gemini-weekly`). It is currently unverified whether `gpt-oss-*` models are tracked under `3p-*` or `gemini-*` by `agy` internals. To verify this, capture the live stdin JSON payload passed to `statusline.sh` while a `gpt-oss` model is active and inspect the `.quota` key structure.
