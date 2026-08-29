#!/bin/bash

set -euo pipefail

readonly ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readonly MANAGER="$ROOT/launcher-entries.sh"
readonly TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT

run_manager() {
  local home="$1" action="$2"
  HOME="$home" XDG_STATE_HOME="$home/state" XDG_DATA_HOME="$home/data" \
    PATH="/usr/bin:/bin" bash "$MANAGER" "$action"
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
if run_manager "$home" status >/dev/null 2>&1; then
  echo "expected incomplete launcher status to be nonzero" >&2
  exit 1
else
  [[ $? == 1 ]]
fi

xdg_home="$TEST_ROOT/xdg-home"
xdg_config="$TEST_ROOT/xdg-config"
xdg_state="$TEST_ROOT/xdg-state"
xdg_data="$TEST_ROOT/xdg-data"
mkdir -p "$xdg_home" "$xdg_config" "$xdg_state" "$xdg_data"
HOME="$xdg_home" XDG_CONFIG_HOME="$xdg_config" XDG_STATE_HOME="$xdg_state" \
  XDG_DATA_HOME="$xdg_data" PATH="/usr/bin:/bin" bash "$MANAGER" install >/dev/null
[[ -f $xdg_state/oligarchy/.operation.lock ]]
[[ -f $xdg_data/applications/oligarchy-tax-department.desktop ]]
[[ ! -e $xdg_home/.local ]]

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

symlink_home="$TEST_ROOT/symlink-home"
mkdir -p "$symlink_home/data/applications"
printf '%s\n' 'external sentinel' >"$symlink_home/sentinel"
ln -s "$symlink_home/sentinel" \
  "$symlink_home/data/applications/oligarchy-pizza-party.desktop"
if timeout 2 env HOME="$symlink_home" XDG_STATE_HOME="$symlink_home/state" \
  XDG_DATA_HOME="$symlink_home/data" PATH="/usr/bin:/bin" \
  bash "$MANAGER" install >/dev/null 2>&1; then
  echo "expected a symlinked launcher target to be refused" >&2
  exit 1
fi
grep -Fqx 'external sentinel' "$symlink_home/sentinel"
[[ -L $symlink_home/data/applications/oligarchy-pizza-party.desktop ]]
[[ ! -e $symlink_home/data/applications/oligarchy-tax-department.desktop ]]
[[ ! -e $symlink_home/data/applications/oligarchy-executive-exit.desktop ]]

fifo_home="$TEST_ROOT/fifo-home"
mkdir -p "$fifo_home/data/applications"
mkfifo "$fifo_home/data/applications/oligarchy-tax-department.desktop"
if timeout 2 env HOME="$fifo_home" XDG_STATE_HOME="$fifo_home/state" \
  XDG_DATA_HOME="$fifo_home/data" PATH="/usr/bin:/bin" \
  bash "$MANAGER" install >/dev/null 2>&1; then
  echo "expected a FIFO launcher target to be refused without blocking" >&2
  exit 1
fi

parent_home="$TEST_ROOT/parent-home"
mkdir -p "$parent_home/data" "$parent_home/external"
ln -s "$parent_home/external" "$parent_home/data/applications"
if run_manager "$parent_home" install >/dev/null 2>&1; then
  echo "expected a symlinked applications parent to be refused" >&2
  exit 1
fi
[[ -z $(find "$parent_home/external" -mindepth 1 -print -quit) ]]

remove_link_home="$TEST_ROOT/remove-link-home"
mkdir -p "$remove_link_home"
run_manager "$remove_link_home" install >/dev/null
printf '%s\n' 'remove sentinel' >"$remove_link_home/sentinel"
rm -- "$remove_link_home/data/applications/oligarchy-pizza-party.desktop"
ln -s "$remove_link_home/sentinel" \
  "$remove_link_home/data/applications/oligarchy-pizza-party.desktop"
if run_manager "$remove_link_home" remove >/dev/null 2>&1; then
  echo "expected a swapped launcher symlink to block removal" >&2
  exit 1
fi
grep -Fqx 'remove sentinel' "$remove_link_home/sentinel"
[[ -f $remove_link_home/data/applications/oligarchy-tax-department.desktop ]]
[[ -f $remove_link_home/data/applications/oligarchy-executive-exit.desktop ]]
[[ -L $remove_link_home/data/applications/oligarchy-pizza-party.desktop ]]

echo "PASS - launcher entries are transactionally installed and removed with bounded no-follow reads, safe parents, and symlink/FIFO refusal"
