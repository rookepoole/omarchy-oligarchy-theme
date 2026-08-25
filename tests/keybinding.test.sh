#!/bin/bash

set -euo pipefail

readonly ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readonly MANAGER="$ROOT/keybinding.sh"
readonly TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT

make_case() {
  local name="$1"
  local directory="$TEST_ROOT/$name"
  mkdir -p "$directory/home/.config/hypr" "$directory/bin"
  cat >"$directory/bin/omarchy" <<'MOCK'
#!/bin/bash
if [[ $* == "menu keybindings --print" ]]; then
  printf '%s\n' "${MOCK_BINDINGS:-SUPER + CTRL + T                    → Activity}"
  exit 0
fi
exit 1
MOCK
  chmod +x "$directory/bin/omarchy"
  printf '%s\n' "$directory"
}

clean=$(make_case clean)
printf '%s\n' '-- personal binding file' >"$clean/home/.config/hypr/bindings.lua"
HOME="$clean/home" PATH="$clean/bin:$PATH" bash "$MANAGER" install >/dev/null
grep -Fqx 'o.bind("SUPER + SHIFT + T", "Tax Department", "omarchy-shell shell toggle rookepoole.oligarchy-tax-department '\''{}'\''")' \
  "$clean/home/.config/hypr/bindings.lua"
HOME="$clean/home" PATH="$clean/bin:$PATH" bash "$MANAGER" install >/dev/null
[[ $(grep -Fc 'OLIGARCHY TAX DEPARTMENT KEYBIND' "$clean/home/.config/hypr/bindings.lua") == 2 ]]
HOME="$clean/home" PATH="$clean/bin:$PATH" bash "$MANAGER" remove >/dev/null
grep -Fqx -- '-- personal binding file' "$clean/home/.config/hypr/bindings.lua"
! grep -Fq 'Tax Department' "$clean/home/.config/hypr/bindings.lua"

conflict=$(make_case conflict)
printf '%s\n' 'o.bind("SHIFT + SUPER + T", "Existing action", "true")' >"$conflict/home/.config/hypr/bindings.lua"
before=$(sha256sum "$conflict/home/.config/hypr/bindings.lua")
if HOME="$conflict/home" PATH="$conflict/bin:$PATH" bash "$MANAGER" install >/dev/null 2>&1; then
  echo "expected an existing user chord to be preserved" >&2
  exit 1
fi
after=$(sha256sum "$conflict/home/.config/hypr/bindings.lua")
[[ $before == "$after" ]]

live_conflict=$(make_case live-conflict)
printf '%s\n' '-- personal binding file' >"$live_conflict/home/.config/hypr/bindings.lua"
if HOME="$live_conflict/home" PATH="$live_conflict/bin:$PATH" \
  MOCK_BINDINGS='SUPER SHIFT + T                    → Existing live action' \
  bash "$MANAGER" install >/dev/null 2>&1; then
  echo "expected a live Hyprland chord conflict to be preserved" >&2
  exit 1
fi
! grep -Fq 'Tax Department' "$live_conflict/home/.config/hypr/bindings.lua"

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
printf '%s\n' '-- exact preimage' >"$rollback/home/.config/hypr/bindings.lua"
printf '0\n' >"$rollback/hyprctl-calls"
cat >"$rollback/bin/hyprctl" <<'MOCK'
#!/bin/bash
set -euo pipefail
root=$(dirname -- "$(dirname -- "$0")")
case "$1" in
  reload) exit 0 ;;
  configerrors)
    calls=$(<"$root/hyprctl-calls")
    calls=$((calls + 1))
    printf '%s\n' "$calls" >"$root/hyprctl-calls"
    [[ $calls -ge 2 ]] && printf 'oligarchy test error\n'
    ;;
  *) exit 1 ;;
esac
MOCK
chmod +x "$rollback/bin/hyprctl"
before=$(sha256sum "$rollback/home/.config/hypr/bindings.lua")
if HOME="$rollback/home" PATH="$rollback/bin:$PATH" HYPRLAND_INSTANCE_SIGNATURE=test \
  bash "$MANAGER" install >/dev/null 2>&1; then
  echo "expected a new Hyprland config error to roll back" >&2
  exit 1
fi
after=$(sha256sum "$rollback/home/.config/hypr/bindings.lua")
[[ $before == "$after" ]]

echo "PASS - keybinding install/remove is idempotent, reversible, collision-safe, marker-safe, and rolls back config errors"
