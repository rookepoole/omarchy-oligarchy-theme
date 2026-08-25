#!/bin/bash

# Install, repair, inspect, or remove OLIGARCHY's one managed Hyprland bind.
# The script owns only the delimited block below. It never unbinds or rewrites
# another action, and a live session is verified against `hyprctl binds`.

set -euo pipefail

readonly ACTION="${1:-install}"
readonly CHORD="SUPER + SHIFT + T"
readonly DESCRIPTION="Tax Department"
readonly PLUGIN_ID="rookepoole.oligarchy-tax-department"
readonly COMMAND="omarchy-shell shell toggle $PLUGIN_ID"
readonly START_MARKER="# >>> OLIGARCHY TAX DEPARTMENT KEYBIND (managed)"
readonly END_MARKER="# <<< OLIGARCHY TAX DEPARTMENT KEYBIND (managed)"
readonly BINDING_LINE="o.bind(\"$CHORD\", \"$DESCRIPTION\", \"$COMMAND\")"
readonly LEGACY_BINDING_LINE="o.bind(\"$CHORD\", \"$DESCRIPTION\", \"$COMMAND '{}'\")"
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

managed_block_line() {
  [[ -f $BINDINGS_FILE ]] || return 1
  awk -v start="$START_MARKER" -v finish="$END_MARKER" '
    $0 == start { inside = 1; next }
    $0 == finish { exit }
    inside { print }
  ' "$BINDINGS_FILE"
}

managed_block_shape_is_valid() {
  local start_line end_line content
  [[ $(marker_count "$START_MARKER") == 1 ]] || return 1
  [[ $(marker_count "$END_MARKER") == 1 ]] || return 1
  start_line=$(grep -Fnx -- "$START_MARKER" "$BINDINGS_FILE")
  end_line=$(grep -Fnx -- "$END_MARKER" "$BINDINGS_FILE")
  start_line=${start_line%%:*}
  end_line=${end_line%%:*}
  (( end_line == start_line + 2 )) || return 1
  content=$(managed_block_line)
  [[ $content == "$BINDING_LINE" || $content == "$LEGACY_BINDING_LINE" ]]
}

managed_block_is_current() {
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
  local backup="$1" existed="$2"
  if [[ $existed == yes ]]; then cp -p -- "$backup" "$BINDINGS_FILE"; else rm -f -- "$BINDINGS_FILE"; fi
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
  local backup="$1" existed="$2" errors
  live_session_available || {
    printf 'OLIGARCHY keybind: persistent binding installed; no live Hyprland session was available to verify.\n'
    return 0
  }

  if ! hyprctl reload >/dev/null 2>&1; then
    restore_prior_file "$backup" "$existed"
    fail "Hyprland rejected the reload; the prior bindings file was restored"
  fi
  errors=$(hyprctl configerrors 2>/dev/null || true)
  if [[ -n $errors ]]; then
    restore_prior_file "$backup" "$existed"
    fail "the binding introduced a Hyprland config error; the prior bindings file was restored"
  fi
  wait_for_live_binding && {
    printf 'OLIGARCHY keybind: live Hyprland resolved %s -> %s.\n' "$CHORD" "$DESCRIPTION"
    return 0
  }

  live_chord_has_other_owner &&
    fail "$CHORD resolved to another live action after reload; OLIGARCHY did not overwrite it"

  # Some Hyprland Lua builds have registered-but-inert reload regressions. The
  # persistent source remains authoritative; eval activates the same owned line
  # in the current Lua state, then the resolved table is checked again.
  if hyprctl eval "$BINDING_LINE" >/dev/null 2>&1 && wait_for_live_binding; then
    printf 'OLIGARCHY keybind: repaired and verified %s in the live Hyprland session.\n' "$CHORD"
    return 0
  fi

  fail "persistent binding is installed but absent from Hyprland's live bind table; run '$0 status' and reboot once"
}

backup_bindings() {
  mkdir -p -- "$STATE_DIR"
  local backup="$STATE_DIR/bindings.lua.$(date +%s%N).bak"
  if [[ -f $BINDINGS_FILE ]]; then cp -p -- "$BINDINGS_FILE" "$backup"; else : >"$backup"; fi
  printf '%s\n' "$backup"
}

write_current_managed_block() {
  local temporary
  temporary=$(mktemp "${BINDINGS_FILE}.oligarchy.XXXXXX")
  awk -v start="$START_MARKER" -v finish="$END_MARKER" -v binding="$BINDING_LINE" '
    $0 == start { print start; print binding; inside = 1; next }
    $0 == finish { print finish; inside = 0; next }
    !inside { print }
    END { if (inside) exit 2 }
  ' "$BINDINGS_FILE" >"$temporary"
  chmod --reference="$BINDINGS_FILE" "$temporary" 2>/dev/null || true
  mv -- "$temporary" "$BINDINGS_FILE"
}

adopt_known_orphan_binding() {
  local temporary
  temporary=$(mktemp "${BINDINGS_FILE}.oligarchy.XXXXXX")
  awk -v current="$BINDING_LINE" -v legacy="$LEGACY_BINDING_LINE" \
      -v start="$START_MARKER" -v finish="$END_MARKER" '
    $0 == current || $0 == legacy {
      replaced++
      print start
      print current
      print finish
      next
    }
    { print }
    END { if (replaced != 1) exit 2 }
  ' "$BINDINGS_FILE" >"$temporary"
  chmod --reference="$BINDINGS_FILE" "$temporary" 2>/dev/null || true
  mv -- "$temporary" "$BINDINGS_FILE"
}

install_binding() {
  local starts ends backup existed=no orphan_count chord_count
  starts=$(marker_count "$START_MARKER")
  ends=$(marker_count "$END_MARKER")

  if [[ $starts != 0 || $ends != 0 ]]; then
    managed_block_shape_is_valid || fail "managed markers are incomplete or edited; refusing to guess"
    preflight_live_config
    [[ -f $BINDINGS_FILE ]] && existed=yes
    backup=$(backup_bindings)
    if managed_block_is_current; then
      printf 'OLIGARCHY keybind: persistent %s binding is current.\n' "$CHORD"
    else
      write_current_managed_block
      printf 'OLIGARCHY keybind: migrated the owned binding to the current command.\n'
    fi
    activate_and_verify_live_binding "$backup" "$existed"
    return 0
  fi

  orphan_count=$(known_orphan_binding_count)
  if (( orphan_count > 0 )); then
    chord_count=$(configured_chord_claim_count)
    (( orphan_count == 1 && chord_count == 1 )) ||
      fail "$CHORD has multiple source claims; no line was adopted or overwritten"
    preflight_live_config
    existed=yes
    backup=$(backup_bindings)
    adopt_known_orphan_binding
    printf 'OLIGARCHY keybind: adopted the earlier unmarked OLIGARCHY binding into the managed block.\n'
    activate_and_verify_live_binding "$backup" "$existed"
    return 0
  fi

  if configured_chord_claimed; then
    fail "$CHORD is already assigned in bindings.lua; no unbind or overwrite was attempted"
  fi
  if live_chord_has_other_owner; then
    fail "$CHORD is already assigned in Hyprland's live table; no unbind or overwrite was attempted"
  fi

  preflight_live_config
  [[ -f $BINDINGS_FILE ]] && existed=yes
  backup=$(backup_bindings)
  mkdir -p -- "$(dirname -- "$BINDINGS_FILE")"
  touch -- "$BINDINGS_FILE"
  printf '\n%s\n%s\n%s\n' "$START_MARKER" "$BINDING_LINE" "$END_MARKER" >>"$BINDINGS_FILE"
  activate_and_verify_live_binding "$backup" "$existed"
}

remove_binding() {
  local starts ends backup existed=yes temporary
  starts=$(marker_count "$START_MARKER")
  ends=$(marker_count "$END_MARKER")
  if [[ $starts == 0 && $ends == 0 ]]; then
    printf 'OLIGARCHY keybind: no managed binding is installed.\n'
    return 0
  fi
  managed_block_shape_is_valid || fail "managed markers are incomplete or edited; refusing to guess"

  preflight_live_config
  backup=$(backup_bindings)
  temporary=$(mktemp "${BINDINGS_FILE}.oligarchy.XXXXXX")
  awk -v start="$START_MARKER" -v finish="$END_MARKER" '
    $0 == start { inside = 1; next }
    $0 == finish { inside = 0; next }
    !inside { print }
    END { if (inside) exit 2 }
  ' "$BINDINGS_FILE" >"$temporary"
  chmod --reference="$BINDINGS_FILE" "$temporary" 2>/dev/null || true
  mv -- "$temporary" "$BINDINGS_FILE"

  if live_session_available; then
    if ! hyprctl reload >/dev/null 2>&1 || [[ -n $(hyprctl configerrors 2>/dev/null || true) ]]; then
      restore_prior_file "$backup" "$existed"
      fail "Hyprland rejected removal; the prior bindings file was restored"
    fi
  fi
  printf 'OLIGARCHY keybind: removed %s; other bindings were preserved.\n' "$CHORD"
}

status_binding() {
  local starts ends orphan_count
  starts=$(marker_count "$START_MARKER")
  ends=$(marker_count "$END_MARKER")
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
    printf 'persistent: invalid managed block | start-markers=%s end-markers=%s\n' "$starts" "$ends"
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

case "$ACTION" in
  install|repair) install_binding ;;
  remove) remove_binding ;;
  status) status_binding ;;
  *) fail "usage: $0 [install|repair|remove|status]" ;;
esac
