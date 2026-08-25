#!/bin/bash

# Install or update OLIGARCHY's native shell layer without assuming which
# half of the repository is already present. Theme installs and plugin installs
# are intentionally separate in Omarchy.

set -euo pipefail

readonly PLUGIN_ID="rookepoole.oligarchy-tax-department"
readonly REPO_URL="https://github.com/rookepoole/omarchy-oligarchy-theme.git"
readonly PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

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

binding_installed=no
if bash "$SCRIPT_DIR/keybinding.sh" install; then
  binding_installed=yes
else
  printf 'OLIGARCHY installer: plugin installed, but the global keybind is not verified; keybinding.sh printed the exact conflict or live-state failure.\n' >&2
fi

launcher_installed=no
if bash "$SCRIPT_DIR/launcher-entries.sh" install; then
  launcher_installed=yes
else
  printf 'OLIGARCHY installer: plugin installed, but launcher entries were skipped to preserve an existing file.\n' >&2
fi

printf 'OLIGARCHY %s is installed, discovered, and enabled.\n' "$version"
if [[ $binding_installed == yes ]]; then
  printf 'Open the Tax Department globally with Super+Shift+T.\n'
else
  printf 'Open TAX·nn from the bar, then run keybinding.sh repair after resolving the reported diagnostic.\n'
fi
if [[ $launcher_installed == yes ]]; then
  printf 'Search Tax Department, Executive Exit Committee, or Pizza Party from the Apps menu.\n'
else
  printf 'Resolve the reported desktop-file conflict before retrying launcher-entries.sh.\n'
fi
printf 'Reboot now to load this plugin generation.\n'
printf 'Binding diagnostics: bash %s/keybinding.sh status\n' "$SCRIPT_DIR"
printf 'The direct plugin opener is: omarchy-shell shell toggle %s\n' "$PLUGIN_ID"
