#!/bin/bash

# Install or remove OLIGARCHY launch surfaces without touching the user's
# Omarchy menu extension. Every target has a unique filename and an ownership
# marker; an unrelated pre-existing file is never overwritten or removed.

set -euo pipefail

readonly ACTION="${1:-install}"
readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly SOURCE_DIR="$SCRIPT_DIR/launcher"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly DEST_DIR="$DATA_HOME/applications"
readonly MANAGED_MARKER="X-Oligarchy-Managed=true"
readonly ENTRIES=(
  oligarchy-tax-department.desktop
  oligarchy-executive-exit.desktop
  oligarchy-pizza-party.desktop
)

fail() {
  printf 'OLIGARCHY launcher: %s\n' "$*" >&2
  exit 1
}

refresh_desktop_index() {
  command -v update-desktop-database >/dev/null 2>&1 &&
    update-desktop-database "$DEST_DIR" >/dev/null 2>&1 || true
  command -v omarchy >/dev/null 2>&1 && omarchy menu refresh >/dev/null 2>&1 || true
}

is_managed() {
  local path="$1"
  [[ -f $path ]] && grep -Fqx -- "$MANAGED_MARKER" "$path"
}

install_entries() {
  local name source target
  for name in "${ENTRIES[@]}"; do
    source="$SOURCE_DIR/$name"
    target="$DEST_DIR/$name"
    [[ -f $source ]] || fail "missing packaged entry: $source"
    if [[ -e $target || -L $target ]]; then
      is_managed "$target" || fail "$target already exists and is not owned by OLIGARCHY; nothing was changed"
    fi
  done

  mkdir -p -- "$DEST_DIR"
  for name in "${ENTRIES[@]}"; do
    install -m 0644 -- "$SOURCE_DIR/$name" "$DEST_DIR/$name"
  done
  refresh_desktop_index
  printf 'OLIGARCHY launcher: installed Tax, Exit Committee, and Pizza Party entries.\n'
}

remove_entries() {
  local name target found=no
  for name in "${ENTRIES[@]}"; do
    target="$DEST_DIR/$name"
    [[ -e $target || -L $target ]] || continue
    is_managed "$target" || fail "$target exists but no longer carries the ownership marker; nothing was removed"
  done

  for name in "${ENTRIES[@]}"; do
    target="$DEST_DIR/$name"
    [[ -e $target || -L $target ]] || continue
    rm -f -- "$target"
    found=yes
  done
  refresh_desktop_index
  if [[ $found == yes ]]; then
    printf 'OLIGARCHY launcher: removed all managed entries.\n'
  else
    printf 'OLIGARCHY launcher: no managed entries are installed.\n'
  fi
}

status_entries() {
  local name missing=0
  for name in "${ENTRIES[@]}"; do
    if is_managed "$DEST_DIR/$name"; then
      printf 'installed: %s\n' "$name"
    else
      printf 'missing: %s\n' "$name"
      missing=1
    fi
  done
  return "$missing"
}

case "$ACTION" in
  install) install_entries ;;
  remove) remove_entries ;;
  status) status_entries ;;
  *) fail "usage: $0 [install|remove|status]" ;;
esac
