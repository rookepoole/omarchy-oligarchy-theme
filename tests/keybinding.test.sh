#!/bin/bash

set -euo pipefail

readonly ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readonly MANAGER="$ROOT/keybinding.sh"
readonly TEST_ROOT=$(mktemp -d)
readonly CURRENT='o.bind("SUPER + SHIFT + T", "Tax Department", "omarchy-shell shell toggle rookepoole.oligarchy-tax-department")'
readonly LEGACY='o.bind("SUPER + SHIFT + T", "Tax Department", "omarchy-shell shell toggle rookepoole.oligarchy-tax-department '\''{}'\''")'
trap 'rm -rf -- "$TEST_ROOT"' EXIT

make_case() {
  local name="$1" directory
  directory="$TEST_ROOT/$name"
  mkdir -p "$directory/home/.config/hypr" "$directory/bin"
  printf '%s\n' "$directory"
}

add_live_hyprctl() {
  local directory="$1"
  printf 'initial\n' >"$directory/live-state"
  : >"$directory/hyprctl-log"
  cat >"$directory/bin/hyprctl" <<'MOCK'
#!/bin/bash
set -euo pipefail
root=$(dirname -- "$(dirname -- "$0")")
printf '%s\n' "$*" >>"$root/hyprctl-log"
record() {
  printf 'bind\n\tmodmask: %s\n\tsubmap: \n\tkey: %s\n\tkeycode: 0\n\tcatchall: false\n\tdescription: %s\n\tdispatcher: __lua\n\targ: 42\n' "$1" "$2" "$3"
}
case "$1" in
  version) printf 'Hyprland 0.56.2\n' ;;
  reload) printf 'reloaded\n' >"$root/live-state" ;;
  configerrors)
    if [[ ${MOCK_LIVE_MODE:-target} == config-error && $(<"$root/live-state") == reloaded ]]; then
      printf 'oligarchy test error\n'
    fi
    ;;
  binds)
    case "${MOCK_LIVE_MODE:-target}:$(<"$root/live-state")" in
      target:*) record 65 T 'Tax Department' ;;
      fallback:active) record 65 'SUPER + SHIFT + T' 'Tax Department' ;;
      other:*) record 65 T 'Existing action' ;;
      *) record 68 T 'Activity' ;;
    esac
    ;;
  eval)
    [[ ${MOCK_LIVE_MODE:-} == fallback ]]
    [[ ${*:2} == 'o.bind("SUPER + SHIFT + T", "Tax Department", "omarchy-shell shell toggle rookepoole.oligarchy-tax-department")' ]]
    printf 'active\n' >"$root/live-state"
    ;;
  *) exit 90 ;;
esac
MOCK
  chmod +x "$directory/bin/hyprctl"
}

run_live() {
  local directory="$1" mode="$2" action="${3:-install}"
  HOME="$directory/home" PATH="$directory/bin:$PATH" \
    HYPRLAND_INSTANCE_SIGNATURE=test MOCK_LIVE_MODE="$mode" \
    bash "$MANAGER" "$action"
}

clean=$(make_case clean)
printf '%s\n' '-- personal binding file' >"$clean/home/.config/hypr/bindings.lua"
HOME="$clean/home" PATH="$clean/bin:$PATH" bash "$MANAGER" install >/dev/null
grep -Fqx "$CURRENT" "$clean/home/.config/hypr/bindings.lua"
HOME="$clean/home" PATH="$clean/bin:$PATH" bash "$MANAGER" install >/dev/null
[[ $(grep -Fc 'OLIGARCHY TAX DEPARTMENT KEYBIND' "$clean/home/.config/hypr/bindings.lua") == 2 ]]
HOME="$clean/home" PATH="$clean/bin:$PATH" bash "$MANAGER" status | grep -F 'persistent: yes' >/dev/null
HOME="$clean/home" PATH="$clean/bin:$PATH" bash "$MANAGER" remove >/dev/null
grep -Fqx -- '-- personal binding file' "$clean/home/.config/hypr/bindings.lua"
! grep -Fq 'Tax Department' "$clean/home/.config/hypr/bindings.lua"

legacy=$(make_case legacy)
printf '%s\n%s\n%s\n' \
  '# >>> OLIGARCHY TAX DEPARTMENT KEYBIND (managed)' "$LEGACY" \
  '# <<< OLIGARCHY TAX DEPARTMENT KEYBIND (managed)' \
  >"$legacy/home/.config/hypr/bindings.lua"
HOME="$legacy/home" PATH="$legacy/bin:$PATH" bash "$MANAGER" install >/dev/null
grep -Fqx "$CURRENT" "$legacy/home/.config/hypr/bindings.lua"
! grep -Fq "'{}'" "$legacy/home/.config/hypr/bindings.lua"

conflict=$(make_case conflict)
printf '%s\n' 'o.bind("SHIFT + SUPER + T", "Existing action", "true")' >"$conflict/home/.config/hypr/bindings.lua"
before=$(sha256sum "$conflict/home/.config/hypr/bindings.lua")
if HOME="$conflict/home" PATH="$conflict/bin:$PATH" bash "$MANAGER" install >/dev/null 2>&1; then
  echo "expected an existing user chord to be preserved" >&2
  exit 1
fi
after=$(sha256sum "$conflict/home/.config/hypr/bindings.lua")
[[ $before == "$after" ]]

live=$(make_case live)
add_live_hyprctl "$live"
printf '%s\n' '-- personal binding file' >"$live/home/.config/hypr/bindings.lua"
run_live "$live" target install >/dev/null
run_live "$live" target status | grep -F 'live: yes' >/dev/null
! grep -q '^eval ' "$live/hyprctl-log"

fallback=$(make_case fallback)
add_live_hyprctl "$fallback"
printf '%s\n' '-- personal binding file' >"$fallback/home/.config/hypr/bindings.lua"
run_live "$fallback" fallback install >/dev/null
grep -Fqx "$CURRENT" "$fallback/home/.config/hypr/bindings.lua"
grep -Fqx "eval $CURRENT" "$fallback/hyprctl-log"
run_live "$fallback" fallback status | grep -F 'live: yes' >/dev/null

live_conflict=$(make_case live-conflict)
add_live_hyprctl "$live_conflict"
printf '%s\n' '-- personal binding file' >"$live_conflict/home/.config/hypr/bindings.lua"
before=$(sha256sum "$live_conflict/home/.config/hypr/bindings.lua")
if run_live "$live_conflict" other install >/dev/null 2>&1; then
  echo "expected a live Hyprland chord conflict to be preserved" >&2
  exit 1
fi
after=$(sha256sum "$live_conflict/home/.config/hypr/bindings.lua")
[[ $before == "$after" ]]

missing=$(make_case missing)
add_live_hyprctl "$missing"
printf '\n%s\n%s\n%s\n' \
  '# >>> OLIGARCHY TAX DEPARTMENT KEYBIND (managed)' "$CURRENT" \
  '# <<< OLIGARCHY TAX DEPARTMENT KEYBIND (managed)' \
  >"$missing/home/.config/hypr/bindings.lua"
if run_live "$missing" missing status >/dev/null 2>&1; then
  echo "expected status to reject a persistent-only live binding" >&2
  exit 1
fi

malformed=$(make_case malformed)
printf '%s\n' '# >>> OLIGARCHY TAX DEPARTMENT KEYBIND (managed)' >"$malformed/home/.config/hypr/bindings.lua"
before=$(sha256sum "$malformed/home/.config/hypr/bindings.lua")
if HOME="$malformed/home" PATH="$malformed/bin:$PATH" bash "$MANAGER" install >/dev/null 2>&1; then
  echo "expected malformed managed markers to be refused" >&2
  exit 1
fi
after=$(sha256sum "$malformed/home/.config/hypr/bindings.lua")
[[ $before == "$after" ]]

rollback=$(make_case rollback)
add_live_hyprctl "$rollback"
printf '%s\n' '-- exact preimage' >"$rollback/home/.config/hypr/bindings.lua"
before=$(sha256sum "$rollback/home/.config/hypr/bindings.lua")
if run_live "$rollback" config-error install >/dev/null 2>&1; then
  echo "expected a new Hyprland config error to roll back" >&2
  exit 1
fi
after=$(sha256sum "$rollback/home/.config/hypr/bindings.lua")
[[ $before == "$after" ]]

echo "PASS - keybinding is current-command, migratable, reversible, collision-safe, live-resolved, self-repairing, and config-error-rollback-safe"
