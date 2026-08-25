#!/bin/bash

set -euo pipefail

readonly ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readonly MANAGER="$ROOT/launcher-entries.sh"
readonly TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT

run_manager() {
  local home="$1" action="$2"
  HOME="$home" XDG_DATA_HOME="$home/data" PATH="/usr/bin:/bin" bash "$MANAGER" "$action"
}

home="$TEST_ROOT/home"
mkdir -p "$home"
run_manager "$home" install >/dev/null

dest="$home/data/applications"
for name in oligarchy-tax-department.desktop oligarchy-executive-exit.desktop oligarchy-pizza-party.desktop; do
  [[ -f $dest/$name ]]
  grep -Fqx 'X-Oligarchy-Managed=true' "$dest/$name"
done
grep -Fqx 'Exec=omarchy-shell shell summon rookepoole.oligarchy-tax-department {}' "$dest/oligarchy-tax-department.desktop"
grep -Fqx 'Exec=omarchy-shell oligarchy-executive-exit open {}' "$dest/oligarchy-executive-exit.desktop"
grep -Fqx 'Exec=omarchy-shell oligarchy-screensaver previewScene 4' "$dest/oligarchy-pizza-party.desktop"

run_manager "$home" install >/dev/null
[[ $(find "$dest" -maxdepth 1 -type f -name 'oligarchy-*.desktop' | wc -l) == 3 ]]
run_manager "$home" status >/dev/null
run_manager "$home" remove >/dev/null
[[ $(find "$dest" -maxdepth 1 -type f -name 'oligarchy-*.desktop' | wc -l) == 0 ]]

conflict_home="$TEST_ROOT/conflict-home"
mkdir -p "$conflict_home/data/applications"
printf '%s\n' '[Desktop Entry]' 'Name=User-owned collision' \
  >"$conflict_home/data/applications/oligarchy-pizza-party.desktop"
before=$(sha256sum "$conflict_home/data/applications/oligarchy-pizza-party.desktop")
if run_manager "$conflict_home" install >/dev/null 2>&1; then
  echo "expected an unowned launcher collision to be refused" >&2
  exit 1
fi
after=$(sha256sum "$conflict_home/data/applications/oligarchy-pizza-party.desktop")
[[ $before == "$after" ]]
[[ ! -e $conflict_home/data/applications/oligarchy-tax-department.desktop ]]
[[ ! -e $conflict_home/data/applications/oligarchy-executive-exit.desktop ]]

edited_home="$TEST_ROOT/edited-home"
mkdir -p "$edited_home"
run_manager "$edited_home" install >/dev/null
sed -i '/X-Oligarchy-Managed=true/d' "$edited_home/data/applications/oligarchy-tax-department.desktop"
if run_manager "$edited_home" remove >/dev/null 2>&1; then
  echo "expected an edited ownership marker to prevent removal" >&2
  exit 1
fi
[[ -f $edited_home/data/applications/oligarchy-tax-department.desktop ]]
[[ -f $edited_home/data/applications/oligarchy-executive-exit.desktop ]]
[[ -f $edited_home/data/applications/oligarchy-pizza-party.desktop ]]

echo "PASS - launcher entries install, update, remove, and refuse unowned or edited targets atomically"
