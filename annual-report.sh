#!/bin/bash

# Read-only terminal surface for OLIGARCHY. It intentionally changes no system
# state and reads the treasury address from the repository's single authority.

set -euo pipefail

readonly REPORT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly TREASURY_FILE="$REPORT_DIR/TREASURY.txt"

[[ -r $TREASURY_FILE ]] || { echo "Annual report unavailable: TREASURY.txt is missing" >&2; exit 1; }
wallet=$(tr -d '\r\n' <"$TREASURY_FILE")
[[ $wallet =~ ^0x[0-9A-Fa-f]{40}$ ]] || { echo "Annual report unavailable: treasury authority is invalid" >&2; exit 1; }

green=$'\033[38;2;166;217;106m'
gold=$'\033[38;2;212;179;90m'
ivory=$'\033[38;2;233;229;214m'
muted=$'\033[38;2;130;136;125m'
red=$'\033[38;2;218;101;94m'
reset=$'\033[0m'
bold=$'\033[1m'

load=$(awk '{print $1}' /proc/loadavg 2>/dev/null || printf '0.00')
memory=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{if(t>0)printf "%.0f%% USED",(t-a)*100/t;else print "UNKNOWN"}' /proc/meminfo 2>/dev/null || printf 'UNKNOWN')
disk=$(df -P / 2>/dev/null | awk 'NR==2{print $5 " LEASED"}' || printf 'UNKNOWN')
uptime=$(awk '{s=int($1);d=int(s/86400);h=int((s%86400)/3600);if(d>0)printf "%dD %dH",d,h;else printf "%dH",h}' /proc/uptime 2>/dev/null || printf 'UNKNOWN')

battery="DESKTOP"
for capacity in /sys/class/power_supply/BAT*/capacity; do
  [[ -r $capacity ]] || continue
  battery="$(<"$capacity")%"
  break
done

workspace="PRIVATE"
assets="UNDISCLOSED"
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  workspace_json=$(hyprctl -j activeworkspace 2>/dev/null || true)
  clients_json=$(hyprctl -j clients 2>/dev/null || true)
  parsed_workspace=$(jq -r '.id // empty' <<<"$workspace_json" 2>/dev/null || true)
  parsed_assets=$(jq -r 'if type == "array" then length else empty end' <<<"$clients_json" 2>/dev/null || true)
  [[ -n $parsed_workspace ]] && workspace="WORKSPACE $parsed_workspace"
  [[ -n $parsed_assets ]] && assets="$parsed_assets WINDOWS"
fi

report_line() {
  printf '%b%-29s%b %b%s%b\n' "$muted" "$1" "$reset" "$2" "$3" "$reset"
}

printf '%b%b' "$green" "$bold"
cat <<'HEADER'
┌──────────────────────────────────────────────────────────────┐
│  OLIGARCHY // CONSOLIDATED ANNUAL REPORT                    │
│  ELITE CAPITAL. PUBLIC CODE. ZERO-DOLLAR PRICING.           │
└──────────────────────────────────────────────────────────────┘
HEADER
printf '%b' "$reset"

printf '\n%bDEPARTMENT OF OLIGARCH REVENUE%b\n' "$gold$bold" "$reset"
printf '%bUNAUDITED FOREVER // PREPARED %s%b\n\n' "$muted" "$(date '+%Y-%m-%d %H:%M %Z')" "$reset"

printf '%bCONSOLIDATED HOLDINGS%b\n' "$green$bold" "$reset"
report_line "LABOR LOAD // 1M" "$green" "$load"
report_line "LIQUID RESERVES" "$gold" "$memory"
report_line "REAL ESTATE" "$green" "$disk"
report_line "REGULATORY CAPTURE" "$green" "$uptime"
report_line "PRIVATE JET FUEL" "$gold" "$battery"

printf '\n%bPORTFOLIO COMPANIES%b\n' "$green$bold" "$reset"
report_line "CONTROLLING INTEREST" "$green" "$workspace"
report_line "CONSOLIDATED ASSETS" "$gold" "$assets"
report_line "MINORITY RIGHTS" "$red" "DRAG-ALONG"

printf '\n%bTREASURY AND VOLUNTARY COMPLIANCE%b\n' "$gold$bold" "$reset"
report_line "NETWORK" "$ivory" "BASE // 8453"
report_line "BENEFICIAL OWNER" "$red" "[TASTEFULLY REDACTED]"
printf '\n%b%s%b\n\n' "$green$bold" "$wallet" "$reset"

if command -v qrencode >/dev/null 2>&1; then
  printf '%b' "$green"
  qrencode --type ASCII --margin 1 --output - "$wallet"
  printf '%b' "$reset"
else
  printf '%bQR RENDERER CLASSIFIED AS A NON-CORE ASSET%b\n' "$muted" "$reset"
fi

printf '\n%bRISK DISCLOSURE%b\n' "$gold$bold" "$reset"
printf '%bPast extraction is not indicative of future mobility. Losses may be socialized.%b\n' "$ivory" "$reset"
printf '%bNo wallet connection, signature, payment request, or remote lookup occurred.%b\n' "$muted" "$reset"
