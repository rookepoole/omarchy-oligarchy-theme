#!/bin/bash

# Install or update OLIGARCHY's native shell layer without assuming which
# half of the repository is already present. Theme installs and plugin installs
# are intentionally separate in Omarchy.

set -euo pipefail

readonly PLUGIN_ID="rookepoole.oligarchy-tax-department"
readonly REPO_URL="https://github.com/rookepoole/omarchy-oligarchy-theme.git"
readonly PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

fail() {
  printf 'OLIGARCHY installer: %s\n' "$*" >&2
  exit 1
}

for command in omarchy omarchy-shell jq git; do
  command -v "$command" >/dev/null 2>&1 || fail "required command '$command' is unavailable"
done

if ! omarchy plugin list --json >/dev/null 2>&1; then
  fail "this Omarchy installation does not expose the current shell-plugin API; update Omarchy, reboot, then run this installer again"
fi

if [[ -e $PLUGIN_DIR || -L $PLUGIN_DIR ]]; then
  [[ -d $PLUGIN_DIR/.git ]] ||
    fail "$PLUGIN_DIR exists but is not a git checkout; it was left untouched"

  printf 'Updating %s...\n' "$PLUGIN_ID"
  if ! omarchy plugin update "$PLUGIN_ID" --yes; then
    fail "update failed; no force-reset or removal was attempted, so any local work remains intact"
  fi
else
  printf 'Adding %s...\n' "$PLUGIN_ID"
  omarchy plugin add "$REPO_URL" --enable --yes
fi

omarchy-shell shell rescanPlugins >/dev/null

plugins=""
for _ in {1..40}; do
  plugins=$(omarchy plugin list --json 2>/dev/null || true)
  if jq -e --arg id "$PLUGIN_ID" 'any(.[]; .id == $id)' <<<"$plugins" >/dev/null 2>&1; then
    break
  fi
  sleep 0.05
done

jq -e --arg id "$PLUGIN_ID" 'any(.[]; .id == $id)' <<<"$plugins" >/dev/null 2>&1 ||
  fail "the checkout is present but omarchy-shell did not discover it"

if ! jq -e --arg id "$PLUGIN_ID" 'any(.[]; .id == $id and .enabled == true)' \
  <<<"$plugins" >/dev/null 2>&1; then
  omarchy plugin enable "$PLUGIN_ID" --section right
fi

version=$(jq -r '.version // "unknown"' "$PLUGIN_DIR/manifest.json")
plugins=$(omarchy plugin list --json)
jq -e --arg id "$PLUGIN_ID" 'any(.[]; .id == $id and .enabled == true)' \
  <<<"$plugins" >/dev/null 2>&1 || fail "plugin was discovered but did not remain enabled"

printf 'OLIGARCHY %s is installed, discovered, and enabled.\n' "$version"
printf 'Restart the Omarchy shell to load this generation: omarchy-restart-shell\n'
printf 'If the old generation remains after that, reboot once.\n'
printf 'Then open the Tax Department from TAX·nn in the bar.\n'
