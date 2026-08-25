#!/bin/bash

# Install or remove OLIGARCHY's one managed Hyprland binding. The script owns
# only the delimited block below; it never unbinds or rewrites another action.

set -euo pipefail

readonly ACTION="install"
readonly REQUESTED_ACTION="${1:-$ACTION}"
readonly CHORD="SUPER + SHIFT + T"
readonly DESCRIPTION="Tax Department"
readonly COMMAND="omarchy-shell shell toggle rookepoole.oligarchy-tax-department '{}'"
readonly START_MARKER="# >>> OLIGARCHY TAX DEPARTMENT KEYBIND (managed)"
readonly END_MARKER="# <<< OLIGARCHY TAX DEPARTMENT KEYBIND (managed)"
readonly BINDING_LINE="o.bind(\"$CHORD\", \"$DESCRIPTION\", \"$COMMAND\")"
readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
readonly BINDINGS_FILE="$CONFIG_HOME/hypr/bindings.lua"
readonly STATE_DIR="$STATE_HOME/oligarchy/keybinding"

fail() {
  printf 'OLIGARCHY keybind: %s\n' "$*" >&2
  exit 1
}

marker_count() {
  local marker="$1"
  [[ -f $BINDINGS_FILE ]] || { printf '0\n'; return; }
  grep -Fxc -- "$marker" "$BINDINGS_FILE" || true
}

managed_block_is_valid() {
  local start_line binding_line end_line
  [[ $(marker_count "$START_MARKER") == 1 ]] || return 1
  [[ $(marker_count "$END_MARKER") == 1 ]] || return 1
  [[ $(grep -Fxc -- "$BINDING_LINE" "$BINDINGS_FILE" || true) == 1 ]] || return 1
  start_line=$(grep -Fnx -- "$START_MARKER" "$BINDINGS_FILE")
  binding_line=$(grep -Fnx -- "$BINDING_LINE" "$BINDINGS_FILE")
  end_line=$(grep -Fnx -- "$END_MARKER" "$BINDINGS_FILE")
  start_line=${start_line%%:*}
  binding_line=${binding_line%%:*}
  end_line=${end_line%%:*}
  (( binding_line == start_line + 1 && end_line == binding_line + 1 ))
}

normalized_chord() {
  local value token key="" has_alt="" has_ctrl="" has_shift="" has_super=""
  value=$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')
  value=${value//+/ }
  for token in $value; do
    case "$token" in
      ALT) has_alt=ALT ;;
      CTRL|CONTROL) has_ctrl=CTRL ;;
      SHIFT) has_shift=SHIFT ;;
      SUPER|META|MOD4) has_super=SUPER ;;
      *) key="$token" ;;
    esac
  done
  printf '%s%s%s%s%s' "$has_alt" "$has_ctrl" "$has_shift" "$has_super" "$key"
}

configured_chord_claimed() {
  local line raw
  [[ -f $BINDINGS_FILE ]] || return 1
  while IFS= read -r line; do
    raw=$(sed -nE 's/^[[:space:]]*(o|hl)\.bind\("([^"]+)".*/\2/p' <<<"$line")
    [[ -n $raw ]] || continue
    [[ $(normalized_chord "$raw") == SHIFTSUPERT ]] && return 0
  done <"$BINDINGS_FILE"
  return 1
}

live_chord_claimed() {
  local listing chord
  command -v omarchy >/dev/null 2>&1 || return 1
  listing=$(omarchy menu keybindings --print 2>/dev/null || true)
  [[ -n $listing ]] || return 1
  while IFS= read -r line; do
    chord=${line%%→*}
    chord=${chord%%$'\t'*}
    [[ $(normalized_chord "$chord") == SHIFTSUPERT ]] && return 0
  done <<<"$listing"
  return 1
}

preflight_live_config() {
  command -v hyprctl >/dev/null 2>&1 || return 0
  [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || return 0
  local errors
  errors=$(hyprctl configerrors 2>/dev/null || true)
  [[ -z $errors ]] || fail "Hyprland already reports config errors; bindings.lua was left untouched"
}

validate_live_config_or_restore() {
  local backup="$1" existed="$2" errors
  command -v hyprctl >/dev/null 2>&1 || return 0
  [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || return 0

  if ! hyprctl reload >/dev/null 2>&1; then
    if [[ $existed == yes ]]; then cp -p -- "$backup" "$BINDINGS_FILE"; else rm -f -- "$BINDINGS_FILE"; fi
    hyprctl reload >/dev/null 2>&1 || true
    fail "Hyprland rejected the reload; the prior bindings file was restored"
  fi
  errors=$(hyprctl configerrors 2>/dev/null || true)
  if [[ -n $errors ]]; then
    if [[ $existed == yes ]]; then cp -p -- "$backup" "$BINDINGS_FILE"; else rm -f -- "$BINDINGS_FILE"; fi
    hyprctl reload >/dev/null 2>&1 || true
    fail "the binding introduced a Hyprland config error; the prior bindings file was restored"
  fi
}

backup_bindings() {
  mkdir -p -- "$STATE_DIR"
  local backup="$STATE_DIR/bindings.lua.$(date +%s%N).bak"
  if [[ -f $BINDINGS_FILE ]]; then cp -p -- "$BINDINGS_FILE" "$backup"; else : >"$backup"; fi
  printf '%s\n' "$backup"
}

install_binding() {
  local starts ends backup existed=no
  starts=$(marker_count "$START_MARKER")
  ends=$(marker_count "$END_MARKER")
  if [[ $starts != 0 || $ends != 0 ]]; then
    managed_block_is_valid || fail "managed markers are incomplete or edited; refusing to guess"
    printf 'OLIGARCHY keybind: %s already opens the Tax Department.\n' "$CHORD"
    return 0
  fi

  if configured_chord_claimed || live_chord_claimed; then
    fail "$CHORD is already assigned; no unbind or overwrite was attempted"
  fi

  preflight_live_config
  [[ -f $BINDINGS_FILE ]] && existed=yes
  backup=$(backup_bindings)
  mkdir -p -- "$(dirname -- "$BINDINGS_FILE")"
  touch -- "$BINDINGS_FILE"
  printf '\n%s\n%s\n%s\n' "$START_MARKER" "$BINDING_LINE" "$END_MARKER" >>"$BINDINGS_FILE"
  validate_live_config_or_restore "$backup" "$existed"
  printf 'OLIGARCHY keybind: installed %s -> Tax Department.\n' "$CHORD"
}

remove_binding() {
  local starts ends backup existed=yes temporary
  starts=$(marker_count "$START_MARKER")
  ends=$(marker_count "$END_MARKER")
  if [[ $starts == 0 && $ends == 0 ]]; then
    printf 'OLIGARCHY keybind: no managed binding is installed.\n'
    return 0
  fi
  managed_block_is_valid || fail "managed markers are incomplete or edited; refusing to guess"

  preflight_live_config
  backup=$(backup_bindings)
  temporary=$(mktemp "${BINDINGS_FILE}.oligarchy.XXXXXX")
  trap 'rm -f -- "${temporary:-}"' EXIT
  awk -v start="$START_MARKER" -v finish="$END_MARKER" '
    $0 == start { inside = 1; next }
    $0 == finish { inside = 0; next }
    !inside { print }
    END { if (inside) exit 2 }
  ' "$BINDINGS_FILE" >"$temporary"
  chmod --reference="$BINDINGS_FILE" "$temporary" 2>/dev/null || true
  mv -- "$temporary" "$BINDINGS_FILE"
  validate_live_config_or_restore "$backup" "$existed"
  printf 'OLIGARCHY keybind: removed %s; other bindings were preserved.\n' "$CHORD"
}

case "$REQUESTED_ACTION" in
  install) install_binding ;;
  remove) remove_binding ;;
  status)
    if managed_block_is_valid; then
      printf 'installed: %s -> %s\n' "$CHORD" "$COMMAND"
    else
      printf 'not installed\n'
      exit 1
    fi
    ;;
  *) fail "usage: $0 [install|remove|status]" ;;
esac
