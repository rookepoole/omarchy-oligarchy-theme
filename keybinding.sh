#!/bin/bash

# Install, repair, inspect, or remove OLIGARCHY's one managed Hyprland bind.
# The script owns only the delimited block below. It never unbinds or rewrites
# another action, and a live session is verified against `hyprctl binds`.

set -euo pipefail

readonly ACTION="${1:-install}"
readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly STATE_HELPER="$SCRIPT_DIR/oligarchy-state"
readonly CHORD="SUPER + SHIFT + T"
readonly DESCRIPTION="Tax Department"
readonly PLUGIN_ID="rookepoole.oligarchy-tax-department"
readonly COMMAND="omarchy-shell shell toggle $PLUGIN_ID"
readonly START_MARKER="-- >>> OLIGARCHY TAX DEPARTMENT KEYBIND (managed)"
readonly END_MARKER="-- <<< OLIGARCHY TAX DEPARTMENT KEYBIND (managed)"
readonly LEGACY_START_MARKER="# >>> OLIGARCHY TAX DEPARTMENT KEYBIND (managed)"
readonly LEGACY_END_MARKER="# <<< OLIGARCHY TAX DEPARTMENT KEYBIND (managed)"
readonly BINDING_LINE="o.bind(\"$CHORD\", \"$DESCRIPTION\", \"$COMMAND\")"
readonly LEGACY_BINDING_LINE="o.bind(\"$CHORD\", \"$DESCRIPTION\", \"$COMMAND '{}'\")"
readonly STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
readonly STATE_DIR="$STATE_HOME/oligarchy/keybinding"
readonly ERROR_LOG="$STATE_DIR/last-config-error.txt"
readonly BINDINGS_FILE=$(mktemp)
EXPECTED_BINDINGS=""

cleanup() {
  rm -f -- "$BINDINGS_FILE"
}
trap cleanup EXIT

fail() {
  printf 'OLIGARCHY keybind: %s\n' "$*" >&2
  exit 1
}

stage_bindings() {
  local status
  chmod 0600 -- "$BINDINGS_FILE"
  if "$STATE_HELPER" keybinding-read >"$BINDINGS_FILE"; then
    EXPECTED_BINDINGS=$(sha256sum "$BINDINGS_FILE")
    EXPECTED_BINDINGS=${EXPECTED_BINDINGS%% *}
    return 0
  else
    status=$?
  fi
  [[ $status == 3 ]] || fail "bindings.lua could not be read through the safe no-follow helper"
  : >"$BINDINGS_FILE"
  EXPECTED_BINDINGS=absent
}

commit_staged_bindings() {
  "$STATE_HELPER" keybinding-commit "$EXPECTED_BINDINGS" "$BINDINGS_FILE" ||
    fail "bindings.lua changed or became unsafe before the atomic commit; nothing was written"
}

marker_count() {
  local marker="$1"
  [[ -f $BINDINGS_FILE ]] || { printf '0\n'; return; }
  grep -Fxc -- "$marker" "$BINDINGS_FILE" || true
}

managed_block_line() {
  local start finish
  [[ -f $BINDINGS_FILE ]] || return 1
  start=$(managed_start_marker) || return 1
  finish=$(managed_end_marker) || return 1
  awk -v start="$start" -v finish="$finish" '
    $0 == start { inside = 1; next }
    $0 == finish { exit }
    inside { print }
  ' "$BINDINGS_FILE"
}

managed_marker_style() {
  local current_starts current_ends legacy_starts legacy_ends
  current_starts=$(marker_count "$START_MARKER")
  current_ends=$(marker_count "$END_MARKER")
  legacy_starts=$(marker_count "$LEGACY_START_MARKER")
  legacy_ends=$(marker_count "$LEGACY_END_MARKER")
  if [[ $current_starts == 1 && $current_ends == 1 && $legacy_starts == 0 && $legacy_ends == 0 ]]; then
    printf 'current\n'
    return 0
  fi
  if [[ $legacy_starts == 1 && $legacy_ends == 1 && $current_starts == 0 && $current_ends == 0 ]]; then
    printf 'legacy\n'
    return 0
  fi
  return 1
}

managed_start_marker() {
  case "$(managed_marker_style)" in
    current) printf '%s\n' "$START_MARKER" ;;
    legacy) printf '%s\n' "$LEGACY_START_MARKER" ;;
    *) return 1 ;;
  esac
}

managed_end_marker() {
  case "$(managed_marker_style)" in
    current) printf '%s\n' "$END_MARKER" ;;
    legacy) printf '%s\n' "$LEGACY_END_MARKER" ;;
    *) return 1 ;;
  esac
}

managed_block_shape_is_valid() {
  local start finish start_line end_line content
  start=$(managed_start_marker) || return 1
  finish=$(managed_end_marker) || return 1
  start_line=$(grep -Fnx -- "$start" "$BINDINGS_FILE")
  end_line=$(grep -Fnx -- "$finish" "$BINDINGS_FILE")
  start_line=${start_line%%:*}
  end_line=${end_line%%:*}
  (( end_line == start_line + 2 )) || return 1
  content=$(managed_block_line)
  [[ $content == "$BINDING_LINE" || $content == "$LEGACY_BINDING_LINE" ]]
}

managed_block_is_current() {
  [[ $(managed_marker_style 2>/dev/null || true) == current ]] &&
    managed_block_shape_is_valid && [[ $(managed_block_line) == "$BINDING_LINE" ]]
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
  [[ $(configured_chord_claim_count) -gt 0 ]]
}

configured_chord_claim_count() {
  local line raw
  local count=0
  [[ -f $BINDINGS_FILE ]] || { printf '0\n'; return; }
  while IFS= read -r line; do
    raw=$(sed -nE 's/^[[:space:]]*(o|hl)\.bind\("([^"]+)".*/\2/p' <<<"$line")
    [[ -n $raw ]] || continue
    [[ $(normalized_chord "$raw") == SHIFTSUPERT ]] && count=$((count + 1))
  done <"$BINDINGS_FILE"
  printf '%s\n' "$count"
}

known_orphan_binding_count() {
  local count=0
  [[ -f $BINDINGS_FILE ]] || { printf '0\n'; return; }
  count=$((count + $(grep -Fxc -- "$BINDING_LINE" "$BINDINGS_FILE" || true)))
  count=$((count + $(grep -Fxc -- "$LEGACY_BINDING_LINE" "$BINDINGS_FILE" || true)))
  printf '%s\n' "$count"
}

live_session_available() {
  command -v hyprctl >/dev/null 2>&1 &&
    [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] &&
    hyprctl version >/dev/null 2>&1
}

# Hyprland 0.56 can emit invalid JSON for binds. Parse the stable plain record
# format used by Omarchy itself: modmask, key, and description are sufficient
# to prove that this chord resolved to our named Lua callback.
live_bind_records() {
  hyprctl binds 2>/dev/null | awk '
    function emit() {
      if (!seen) return
      printf "%s\x1f%s\x1f%s\n", f["modmask"], f["key"], f["description"]
    }
    /^bind/ { emit(); seen = 1; delete f; next }
    seen && match($0, /^\t[a-z]+: /) { f[substr($0, 2, RLENGTH - 3)] = substr($0, RLENGTH + 1) }
    END { emit() }
  '
}

live_record_is_target_chord() {
  local modmask="$1" key="${2^^}"
  [[ $modmask == 65 ]] || return 1
  [[ $key == T || $key == *" + T" ]]
}

live_managed_binding_present() {
  local modmask key description
  live_session_available || return 1
  while IFS=$'\x1f' read -r modmask key description; do
    live_record_is_target_chord "$modmask" "$key" || continue
    [[ $description == "$DESCRIPTION" ]] && return 0
  done < <(live_bind_records)
  return 1
}

live_chord_has_other_owner() {
  local modmask key description
  live_session_available || return 1
  while IFS=$'\x1f' read -r modmask key description; do
    live_record_is_target_chord "$modmask" "$key" || continue
    [[ $description != "$DESCRIPTION" ]] && return 0
  done < <(live_bind_records)
  return 1
}

preflight_live_config() {
  live_session_available || return 0
  local errors
  errors=$(hyprctl configerrors 2>/dev/null || true)
  [[ -z $errors ]] || fail "Hyprland already reports config errors; bindings.lua was left untouched"
}

restore_prior_file() {
  local backup="$1"
  "$STATE_HELPER" keybinding-restore "$backup" ||
    fail "the prior bindings file could not be restored through the safe no-follow helper"
  hyprctl reload >/dev/null 2>&1 || true
}

wait_for_live_binding() {
  local _
  for _ in {1..20}; do
    live_managed_binding_present && return 0
    sleep 0.05
  done
  return 1
}

activate_and_verify_live_binding() {
  local backup errors summary diagnostic
  backup=$(commit_staged_bindings)
  live_session_available || {
    printf 'OLIGARCHY keybind: persistent binding installed; no live Hyprland session was available to verify.\n'
    return 0
  }

  if ! hyprctl reload >/dev/null 2>&1; then
    restore_prior_file "$backup"
    fail "Hyprland rejected the reload; the prior bindings file was restored"
  fi
  errors=$(hyprctl configerrors 2>/dev/null || true)
  if [[ -n $errors ]]; then
    diagnostic="$ERROR_LOG"
    if ! printf '%s\n' "$errors" | "$STATE_HELPER" keybinding-log; then
      diagnostic="unavailable because the diagnostic path was unsafe"
    fi
    summary=${errors//$'\n'/ | }
    restore_prior_file "$backup"
    fail "the binding introduced a Hyprland config error: $summary; the prior bindings file was restored; full diagnostic: $diagnostic"
  fi
  wait_for_live_binding && {
    printf 'OLIGARCHY keybind: live Hyprland resolved %s -> %s.\n' "$CHORD" "$DESCRIPTION"
    return 0
  }

  if live_chord_has_other_owner; then
    restore_prior_file "$backup"
    fail "$CHORD resolved to another live action after reload; the prior bindings file was restored"
  fi

  # Some Hyprland Lua builds have registered-but-inert reload regressions. The
  # persistent source remains authoritative; eval activates the same owned line
  # in the current Lua state, then the resolved table is checked again.
  if hyprctl eval "$BINDING_LINE" >/dev/null 2>&1 && wait_for_live_binding; then
    printf 'OLIGARCHY keybind: repaired and verified %s in the live Hyprland session.\n' "$CHORD"
    return 0
  fi

  restore_prior_file "$backup"
  fail "persistent binding was absent from Hyprland's live bind table; the prior bindings file was restored"
}

prepend_current_managed_block() {
  local source="$1" temporary has_bom=no
  temporary=$(mktemp "${BINDINGS_FILE}.oligarchy.XXXXXX")
  if [[ -s $source && $(head -c 3 -- "$source" | od -An -tx1 | tr -d '[:space:]') == efbbbf ]]; then
    has_bom=yes
  fi
  if [[ $has_bom == yes ]]; then
    printf '\357\273\277\n%s\n%s\n%s\n' "$START_MARKER" "$BINDING_LINE" "$END_MARKER" >"$temporary"
    tail -c +4 -- "$source" >>"$temporary"
  else
    printf '%s\n%s\n%s\n' "$START_MARKER" "$BINDING_LINE" "$END_MARKER" >"$temporary"
    cat -- "$source" >>"$temporary"
  fi
  chmod --reference="$BINDINGS_FILE" "$temporary" 2>/dev/null || true
  mv -- "$temporary" "$BINDINGS_FILE"
}

strip_managed_block() {
  local source="$1" target="$2" start finish
  start=$(managed_start_marker) || return 1
  finish=$(managed_end_marker) || return 1
  awk -v start="$start" -v finish="$finish" '
    $0 == start { inside = 1; found++; next }
    $0 == finish { inside = 0; next }
    !inside { print }
    END { if (inside || found != 1) exit 2 }
  ' "$source" >"$target"
}

normalize_managed_block_to_top() {
  local body
  body=$(mktemp "${BINDINGS_FILE}.oligarchy-body.XXXXXX")
  strip_managed_block "$BINDINGS_FILE" "$body"
  prepend_current_managed_block "$body"
  rm -f -- "$body"
}

adopt_known_orphan_binding() {
  local body
  body=$(mktemp "${BINDINGS_FILE}.oligarchy-body.XXXXXX")
  awk -v current="$BINDING_LINE" -v legacy="$LEGACY_BINDING_LINE" '
    $0 == current || $0 == legacy { removed++; next }
    { print }
    END { if (removed != 1) exit 2 }
  ' "$BINDINGS_FILE" >"$body"
  prepend_current_managed_block "$body"
  rm -f -- "$body"
}

install_binding() {
  local starts ends orphan_count chord_count marker_style
  starts=$(( $(marker_count "$START_MARKER") + $(marker_count "$LEGACY_START_MARKER") ))
  ends=$(( $(marker_count "$END_MARKER") + $(marker_count "$LEGACY_END_MARKER") ))

  if [[ $starts != 0 || $ends != 0 ]]; then
    managed_block_shape_is_valid || fail "managed markers are incomplete or edited; refusing to guess"
    marker_style=$(managed_marker_style)
    [[ $marker_style == current ]] && preflight_live_config
    if managed_block_is_current; then
      printf 'OLIGARCHY keybind: persistent %s binding is current; normalizing its safe module position.\n' "$CHORD"
    elif [[ $marker_style == legacy ]]; then
      printf 'OLIGARCHY keybind: replacing the shipped shell-style Lua markers with valid Lua comments.\n'
    else
      printf 'OLIGARCHY keybind: migrated the owned binding to the current command.\n'
    fi
    normalize_managed_block_to_top
    activate_and_verify_live_binding
    return 0
  fi

  orphan_count=$(known_orphan_binding_count)
  if (( orphan_count > 0 )); then
    chord_count=$(configured_chord_claim_count)
    (( orphan_count == 1 && chord_count == 1 )) ||
      fail "$CHORD has multiple source claims; no line was adopted or overwritten"
    preflight_live_config
    adopt_known_orphan_binding
    printf 'OLIGARCHY keybind: adopted the earlier unmarked OLIGARCHY binding into the managed block.\n'
    activate_and_verify_live_binding
    return 0
  fi

  if configured_chord_claimed; then
    fail "$CHORD is already assigned in bindings.lua; no unbind or overwrite was attempted"
  fi
  if live_chord_has_other_owner; then
    fail "$CHORD is already assigned in Hyprland's live table; no unbind or overwrite was attempted"
  fi

  preflight_live_config
  prepend_current_managed_block "$BINDINGS_FILE"
  activate_and_verify_live_binding
}

remove_binding() {
  local starts ends backup temporary start finish
  starts=$(( $(marker_count "$START_MARKER") + $(marker_count "$LEGACY_START_MARKER") ))
  ends=$(( $(marker_count "$END_MARKER") + $(marker_count "$LEGACY_END_MARKER") ))
  if [[ $starts == 0 && $ends == 0 ]]; then
    printf 'OLIGARCHY keybind: no managed binding is installed.\n'
    return 0
  fi
  managed_block_shape_is_valid || fail "managed markers are incomplete or edited; refusing to guess"

  preflight_live_config
  temporary=$(mktemp "${BINDINGS_FILE}.oligarchy.XXXXXX")
  start=$(managed_start_marker)
  finish=$(managed_end_marker)
  awk -v start="$start" -v finish="$finish" '
    $0 == start { inside = 1; next }
    $0 == finish { inside = 0; next }
    !inside { print }
    END { if (inside) exit 2 }
  ' "$BINDINGS_FILE" >"$temporary"
  chmod --reference="$BINDINGS_FILE" "$temporary" 2>/dev/null || true
  mv -- "$temporary" "$BINDINGS_FILE"

  backup=$(commit_staged_bindings)

  if live_session_available; then
    if ! hyprctl reload >/dev/null 2>&1 || [[ -n $(hyprctl configerrors 2>/dev/null || true) ]]; then
      restore_prior_file "$backup"
      fail "Hyprland rejected removal; the prior bindings file was restored"
    fi
  fi
  printf 'OLIGARCHY keybind: removed %s; other bindings were preserved.\n' "$CHORD"
}

status_binding() {
  local starts ends orphan_count current_starts current_ends legacy_starts legacy_ends
  current_starts=$(marker_count "$START_MARKER")
  current_ends=$(marker_count "$END_MARKER")
  legacy_starts=$(marker_count "$LEGACY_START_MARKER")
  legacy_ends=$(marker_count "$LEGACY_END_MARKER")
  starts=$((current_starts + legacy_starts))
  ends=$((current_ends + legacy_ends))
  if [[ $starts == 0 && $ends == 0 ]]; then
    orphan_count=$(known_orphan_binding_count)
    if (( orphan_count == 1 )); then
      printf 'persistent: unmarked OLIGARCHY binding (run repair to adopt it safely)\n'
    elif (( orphan_count > 1 )); then
      printf 'persistent: ambiguous OLIGARCHY duplicates (manual review required)\n'
    else
      printf 'persistent: missing (run repair to install it)\n'
    fi
    return 1
  fi
  if ! managed_block_shape_is_valid; then
    printf 'persistent: invalid managed block | lua-markers=%s/%s legacy-markers=%s/%s\n' \
      "$current_starts" "$current_ends" "$legacy_starts" "$legacy_ends"
    return 1
  fi
  if ! managed_block_is_current; then
    printf 'persistent: legacy command (run install to migrate)\n'
    return 1
  fi
  printf 'persistent: yes | %s -> %s\n' "$CHORD" "$COMMAND"
  if ! live_session_available; then
    printf 'live: unavailable (run inside the Hyprland desktop session)\n'
    return 0
  fi
  if live_managed_binding_present; then
    printf 'live: yes | resolved by Hyprland\n'
    return 0
  fi
  printf 'live: no | run install to repair, then reboot once if still absent\n'
  return 1
}

stage_bindings

case "$ACTION" in
  install|repair) install_binding ;;
  remove) remove_binding ;;
  status) status_binding ;;
  *) fail "usage: $0 [install|repair|remove|status]" ;;
esac
