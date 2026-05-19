#!/usr/bin/env bash
# logtop — `top` for log files. Live-tail any log and group lines by pattern
# (IP, HTTP status, log level, custom regex). Updates in place.
#
#   bash logtop.sh /var/log/nginx/access.log               # group by IP
#   bash logtop.sh /var/log/nginx/access.log --by status   # by HTTP status
#   bash logtop.sh /var/log/syslog --by level              # log level
#   bash logtop.sh /var/log/app.log --by 'ERROR.*'         # custom regex
#
set -u
VERSION="1.0.0"

FILE="${1:-}"
MODE="ip"
INTERVAL=1
TOP=20

shift 2>/dev/null || true
while [ $# -gt 0 ]; do
    case "$1" in
        --by) MODE="$2"; shift ;;
        --top) TOP="$2"; shift ;;
        --interval) INTERVAL="$2"; shift ;;
    esac
    shift
done

if [ -z "$FILE" ] || [ ! -r "$FILE" ]; then
    cat <<USAGE
logtop v$VERSION
  bash logtop.sh <logfile> [--by ip|status|level|<regex>] [--top 20] [--interval 1]

Examples:
  bash logtop.sh /var/log/nginx/access.log
  bash logtop.sh /var/log/nginx/access.log --by status
  bash logtop.sh /var/log/auth.log         --by 'Failed password.*from ([0-9.]+)'
USAGE
    exit 1
fi

if [ -t 1 ]; then
    B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'
    G=$'\033[32m'; Y=$'\033[33m'; RED=$'\033[31m'; C=$'\033[36m'
    CLR_SCREEN=$'\033[2J\033[H'
else B=""; D=""; R=""; G=""; Y=""; RED=""; C=""; CLR_SCREEN=""; fi

# pick extraction regex based on mode
case "$MODE" in
    ip)
        PATTERN='([0-9]{1,3}\.){3}[0-9]{1,3}'
        LABEL="IP address"
        ;;
    status)
        # Common nginx/apache combined log: "GET / HTTP/1.1" 200
        PATTERN='" [0-9]{3}'
        LABEL="HTTP status"
        ;;
    level)
        PATTERN='(DEBUG|INFO|WARN|WARNING|ERROR|CRITICAL|FATAL|NOTICE)'
        LABEL="Log level"
        ;;
    *)
        PATTERN="$MODE"
        LABEL="custom: $MODE"
        ;;
esac

trap "tput cnorm 2>/dev/null; exit 0" INT TERM
tput civis 2>/dev/null || true

declare -A COUNTS
TOTAL=0
START=$(date +%s)

# Use tail -F to follow + handle rotations
tail -n 100 -F "$FILE" 2>/dev/null | while IFS= read -r line; do
    MATCH=$(echo "$line" | grep -oE "$PATTERN" | head -1)
    [ -z "$MATCH" ] && continue
    # clean for "status" mode: extract just the 3-digit code
    if [ "$MODE" = "status" ]; then MATCH=$(echo "$MATCH" | grep -oE '[0-9]{3}'); fi
    COUNTS["$MATCH"]=$(( ${COUNTS["$MATCH"]:-0} + 1 ))
    TOTAL=$((TOTAL + 1))

    NOW=$(date +%s)
    if [ $((NOW - START)) -ge "$INTERVAL" ]; then
        # render
        printf '%s' "$CLR_SCREEN"
        printf '%slogtop v%s%s · %s · %s · %d lines · %ds elapsed\n\n' \
            "$B" "$VERSION" "$R" "$FILE" "$LABEL" "$TOTAL" "$NOW"
        printf '  %s%-30s  %10s  %s%s\n' "$B" "VALUE" "COUNT" "PCT" "$R"
        printf '  %s' "$D"; printf -- '─%.0s' {1..58}; printf '%s\n' "$R"

        # sort + top N
        for key in "${!COUNTS[@]}"; do
            printf '%d %s\n' "${COUNTS[$key]}" "$key"
        done | sort -rn | head -n "$TOP" | while read -r cnt val; do
            pct=$(awk -v c="$cnt" -v t="$TOTAL" 'BEGIN{printf "%.1f", (c/t)*100}')
            # bar
            bar_w=$(awk -v p="$pct" 'BEGIN{printf "%d", p/3}')
            bar=$(printf '█%.0s' $(seq 1 $bar_w) 2>/dev/null)
            # color by mode
            col="$C"
            case "$MODE" in
                status)
                    case "${val:0:1}" in
                        2) col="$G" ;; 3) col="$C" ;; 4) col="$Y" ;; 5) col="$RED" ;;
                    esac ;;
                level)
                    case "$val" in
                        ERROR|CRITICAL|FATAL) col="$RED" ;;
                        WARN|WARNING) col="$Y" ;;
                        INFO|NOTICE) col="$G" ;;
                        DEBUG) col="$D" ;;
                    esac ;;
            esac
            printf '  %s%-30s%s  %10d  %5s%%  %s%s%s\n' \
                "$col" "$val" "$R" "$cnt" "$pct" "$D" "$bar" "$R"
        done
        START=$NOW
    fi
done
