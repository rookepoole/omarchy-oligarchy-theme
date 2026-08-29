#!/bin/bash

# Install or remove OLIGARCHY launch surfaces through the descriptor-anchored
# state helper. The shell wrapper performs no launcher file reads or writes.

set -euo pipefail

readonly ACTION="${1:-install}"
readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly STATE_HELPER="$SCRIPT_DIR/oligarchy-state"

fail() {
  printf 'OLIGARCHY launcher: %s\n' "$*" >&2
  exit 1
}

refresh_menu() {
  command -v omarchy >/dev/null 2>&1 && omarchy menu refresh >/dev/null 2>&1 || true
}

case "$ACTION" in
  install)
    "$STATE_HELPER" launcher-install ||
      fail "unsafe, edited, or unowned launcher target detected; nothing was installed"
    refresh_menu
    printf 'OLIGARCHY launcher: installed Tax, Exit Committee, and Pizza Party entries.\n'
    ;;
  remove)
    result=$("$STATE_HELPER" launcher-remove) ||
      fail "unsafe or edited launcher target detected; nothing was removed"
    refresh_menu
    if [[ $result == removed ]]; then
      printf 'OLIGARCHY launcher: removed all managed entries.\n'
    else
      printf 'OLIGARCHY launcher: no managed entries are installed.\n'
    fi
    ;;
  status)
    if "$STATE_HELPER" launcher-status; then
      exit 0
    else
      status=$?
      [[ $status == 3 ]] && exit 1
      exit "$status"
    fi
    ;;
  *) fail "usage: $0 [install|remove|status]" ;;
esac
