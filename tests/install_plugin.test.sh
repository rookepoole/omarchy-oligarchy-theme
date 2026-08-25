#!/bin/bash

set -euo pipefail

readonly ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readonly INSTALLER="$ROOT/install-plugin.sh"
readonly PLUGIN_ID="rookepoole.oligarchy-tax-department"
readonly TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT

new_case() {
  local name="$1"
  local directory="$TEST_ROOT/$name"
  mkdir -p "$directory/bin" "$directory/home"
  printf 'absent\n' >"$directory/state"
  : >"$directory/log"

  cat >"$directory/bin/omarchy" <<'MOCK'
#!/bin/bash
set -euo pipefail
case_root=$(dirname -- "$(dirname -- "$HOME")")/$(basename -- "$(dirname -- "$HOME")")
case "$*" in
  "plugin list --json")
    case "$(cat "$case_root/state")" in
      absent) printf '[]\n' ;;
      disabled) printf '[{"id":"rookepoole.oligarchy-tax-department","enabled":false}]\n' ;;
      enabled) printf '[{"id":"rookepoole.oligarchy-tax-department","enabled":true}]\n' ;;
      api-fail) exit 1 ;;
    esac
    ;;
  "plugin update rookepoole.oligarchy-tax-department --yes")
    printf 'update\n' >>"$case_root/log"
    ;;
  "plugin add https://github.com/rookepoole/omarchy-oligarchy-theme.git --enable --yes")
    printf 'add\n' >>"$case_root/log"
    plugin_dir="$HOME/.config/omarchy/plugins/rookepoole.oligarchy-tax-department"
    mkdir -p "$plugin_dir/.git"
    printf '{"version":"4.3.1"}\n' >"$plugin_dir/manifest.json"
    printf 'enabled\n' >"$case_root/state"
    ;;
  "menu keybindings --print")
    printf 'SUPER + CTRL + T                    → Activity\n'
    ;;
  "plugin enable rookepoole.oligarchy-tax-department --section right")
    printf 'enable\n' >>"$case_root/log"
    printf 'enabled\n' >"$case_root/state"
    ;;
  *)
    printf 'unexpected omarchy call: %s\n' "$*" >&2
    exit 90
    ;;
esac
MOCK

  cat >"$directory/bin/omarchy-shell" <<'MOCK'
#!/bin/bash
set -euo pipefail
[[ $* == "shell rescanPlugins" ]]
MOCK

  cat >"$directory/bin/jq" <<'MOCK'
#!/bin/bash
set -euo pipefail
arguments="$*"
if [[ $arguments == *'.version // "unknown"'* ]]; then
  file="${@: -1}"
  sed -nE 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$file"
  exit 0
fi
input=$(cat)
if [[ $arguments == *'.enabled == true'* ]]; then
  [[ $input == *'"id":"rookepoole.oligarchy-tax-department"'* && $input == *'"enabled":true'* ]]
else
  [[ $input == *'"id":"rookepoole.oligarchy-tax-department"'* ]]
fi
MOCK

  chmod +x "$directory/bin/omarchy" "$directory/bin/omarchy-shell" "$directory/bin/jq"
  printf '%s\n' "$directory"
}

run_installer() {
  local directory="$1"
  HOME="$directory/home" PATH="$directory/bin:$PATH" bash "$INSTALLER"
}

absent=$(new_case absent)
absent_output=$(run_installer "$absent")
grep -qx 'add' "$absent/log"
grep -qx 'enabled' "$absent/state"
grep -F 'omarchy-restart-shell' <<<"$absent_output" >/dev/null
grep -F 'reboot once' <<<"$absent_output" >/dev/null
grep -F 'Super+Shift+T' <<<"$absent_output" >/dev/null
grep -Fqx 'o.bind("SUPER + SHIFT + T", "Tax Department", "omarchy-shell shell toggle rookepoole.oligarchy-tax-department '\''{}'\''")' \
  "$absent/home/.config/hypr/bindings.lua"

present=$(new_case present)
plugin_dir="$present/home/.config/omarchy/plugins/$PLUGIN_ID"
mkdir -p "$plugin_dir/.git"
printf '{"version":"2.0.1"}\n' >"$plugin_dir/manifest.json"
printf 'disabled\n' >"$present/state"
run_installer "$present" >/dev/null
printf 'update\nenable\n' | diff -u - "$present/log"
grep -qx 'enabled' "$present/state"

non_git=$(new_case non-git)
mkdir -p "$non_git/home/.config/omarchy/plugins/$PLUGIN_ID"
printf 'preserve me\n' >"$non_git/home/.config/omarchy/plugins/$PLUGIN_ID/local-work"
if run_installer "$non_git" >/dev/null 2>&1; then
  echo "expected a non-git checkout to be refused" >&2
  exit 1
fi
grep -qx 'preserve me' "$non_git/home/.config/omarchy/plugins/$PLUGIN_ID/local-work"
[[ ! -s $non_git/log ]]

old_api=$(new_case old-api)
printf 'api-fail\n' >"$old_api/state"
if run_installer "$old_api" >/dev/null 2>&1; then
  echo "expected an unavailable plugin API to be refused" >&2
  exit 1
fi
[[ ! -s $old_api/log ]]

binding_conflict=$(new_case binding-conflict)
mkdir -p "$binding_conflict/home/.config/hypr"
printf '%s\n' 'o.bind("SUPER + SHIFT + T", "Existing action", "true")' \
  >"$binding_conflict/home/.config/hypr/bindings.lua"
conflict_output=$(run_installer "$binding_conflict" 2>&1)
grep -F 'global keybind was skipped' <<<"$conflict_output" >/dev/null
grep -Fqx 'o.bind("SUPER + SHIFT + T", "Existing action", "true")' \
  "$binding_conflict/home/.config/hypr/bindings.lua"

echo "PASS - installer handles add, update, enable, lifecycle guidance, preservation, old-API refusal, and keybind conflicts"
