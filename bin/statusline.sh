#!/bin/bash
input=$(cat)
now=$(date +%s)

C_RESET=$'\e[0m'
C_PURPLE=$'\e[38;2;167;139;250m'
C_GREEN=$'\e[38;2;130;180;100m'
C_AMBER=$'\e[38;2;229;192;123m'
C_RED=$'\e[38;2;224;108;117m'
C_DIM=$'\e[38;2;92;99;112m'

color_for_pct() {
    local pct=$1
    if [ "$pct" -ge 80 ]; then printf "%s" "$C_RED"
    elif [ "$pct" -ge 60 ]; then printf "%s" "$C_AMBER"
    else printf "%s" "$C_GREEN"; fi
}

GAUGE_SEGMENTS=5
GAUGE_PCT_PER_SEGMENT=20

build_gauge() {
    local pct=$1
    if ! [[ "$pct" =~ ^[0-9]+$ ]]; then pct=0; fi
    local filled=$(( pct / GAUGE_PCT_PER_SEGMENT ))
    [ $filled -gt $GAUGE_SEGMENTS ] && filled=$GAUGE_SEGMENTS
    local empty=$(( GAUGE_SEGMENTS - filled ))
    local f="" e=""
    for ((i=0; i<filled; i++)); do f="${f}▰"; done
    for ((i=0; i<empty; i++)); do e="${e}▱"; done
    local c; c=$(color_for_pct "$pct")
    printf "%s%s%s%s" "$c" "$f" "$C_DIM" "$e"
}

to_epoch() {
    # GNU date (-d) parses full ISO8601 including milliseconds/Z directly, so it
    # gets the raw $1. BSD/macOS date (-j -f) needs an exact strptime format, so
    # it gets the trimmed $iso (ms and trailing Z stripped) as a fallback.
    local iso="${1%%.*}"  # ミリ秒以降を除去 (e.g. .123Z)
    iso="${iso%Z}"        # 末尾のZを除去
    date -d "$1" +%s 2>/dev/null || \
    date -j -f "%Y-%m-%dT%H:%M:%S" "$iso" +%s 2>/dev/null || \
    echo ""
}

fmt_epoch_hm() {
    date -d "@$1" "+%H:%M" 2>/dev/null || date -r "$1" "+%H:%M" 2>/dev/null || echo "soon"
}

# Resolves an ISO timestamp to a positive epoch diff from now, or prints "soon"
# and returns 1 if the timestamp is missing/invalid/already past.
resolve_reset_diff() {
    if [ -z "$1" ] || [ "$1" = "null" ]; then
        echo "soon"; return 1
    fi
    local epoch; epoch=$(to_epoch "$1")
    if [ -z "$epoch" ]; then
        echo "soon"; return 1
    fi
    local diff=$(( epoch - now ))
    if [ $diff -le 0 ]; then
        echo "soon"; return 1
    fi
    echo "$diff"
    return 0
}

fmt_reset_hm() {
    local diff; diff=$(resolve_reset_diff "$1") || { echo "$diff"; return; }
    local epoch=$(( now + diff ))
    fmt_epoch_hm "$epoch"
}

fmt_reset_dh() {
    local diff; diff=$(resolve_reset_diff "$1") || { echo "$diff"; return; }
    local d=$(( diff / 86400 ))
    local h=$(( (diff % 86400) / 3600 ))
    local m=$(( (diff % 3600) / 60 ))
    if [ $d -gt 0 ]; then echo "${d}d${h}h"; else echo "${h}h${m}m"; fi
}

eval "$(echo "$input" | jq -r '
    "model_display=" + (.model.display_name // "" | @sh) + "\n" +
    "model_id="      + (.model.id // "" | @sh)
' 2>/dev/null)"

if echo "$model_id" | grep -qiE 'claude|anthropic|3p'; then
    q5h_key="3p-5h"; qwk_key="3p-weekly"
else
    q5h_key="gemini-5h"; qwk_key="gemini-weekly"
fi

eval "$(echo "$input" | jq -r --arg q5h "$q5h_key" --arg qwk "$qwk_key" '
    "h5_pct="   + (if .quota[$q5h].remaining_fraction != null then (((1 - .quota[$q5h].remaining_fraction) * 100) | floor | tostring) else "" end | @sh) + "\n" +
    "h5_reset=" + (.quota[$q5h].reset_time // "" | @sh) + "\n" +
    "d7_pct="   + (if .quota[$qwk].remaining_fraction != null then (((1 - .quota[$qwk].remaining_fraction) * 100) | floor | tostring) else "" end | @sh) + "\n" +
    "d7_reset=" + (.quota[$qwk].reset_time // "" | @sh)
' 2>/dev/null)"

out=""

if [ -n "$model_display" ]; then
    model_short=$(echo "$model_display" | tr -d ' ')
    if echo "$model_id" | grep -qiE 'opus|sonnet|gemini.*pro'; then
        out="${C_RED}!!${model_short}${C_RESET}"
    else
        out="${C_PURPLE}${model_short}${C_RESET}"
    fi
fi

if [ -n "$h5_pct" ]; then
    rst=$(fmt_reset_hm "$h5_reset")
    c=$(color_for_pct "$h5_pct")
    gauge=$(build_gauge "$h5_pct")
    [ -n "$out" ] && out="$out "
    out="${out}${C_DIM}Session:${C_RESET}${gauge}${C_RESET}${c}${h5_pct}%${C_DIM}(${rst})${C_RESET}"
fi

if [ -n "$d7_pct" ]; then
    rst=$(fmt_reset_dh "$d7_reset")
    c=$(color_for_pct "$d7_pct")
    gauge=$(build_gauge "$d7_pct")
    [ -n "$out" ] && out="$out "
    out="${out}${C_DIM}Week:${C_RESET}${gauge}${C_RESET}${c}${d7_pct}%${C_DIM}(${rst})${C_RESET}"
fi

printf "%s" "$out"
