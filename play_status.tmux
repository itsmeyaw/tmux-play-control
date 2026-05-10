#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value
  option_value=$(tmux show-option -gqv "$option")
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

set_tmux_option() {
  tmux set-option -gq "$1" "$2"
}

do_interpolation() {
  local string="$1"
  local play_status="#($CURRENT_DIR/scripts/play_status.sh)"
  echo "$string" | sed "s|#{play_control}|${play_status}|g"
}

update_tmux_option() {
  local option="$1"
  local option_value
  option_value=$(get_tmux_option "$option")
  local new_option_value
  new_option_value=$(do_interpolation "$option_value")
  set_tmux_option "$option" "$new_option_value"
}

setup_keybindings() {
  local key_toggle key_next key_prev key_seek_forward key_seek_backward
  key_toggle=$(get_tmux_option "@play_control_toggle" "P")
  key_next=$(get_tmux_option "@play_control_next" "N")
  key_prev=$(get_tmux_option "@play_control_prev" "B")
  key_seek_forward=$(get_tmux_option "@play_control_seek_forward" "}")
  key_seek_backward=$(get_tmux_option "@play_control_seek_backward" "{")

  tmux bind-key "$key_toggle" run-shell "$CURRENT_DIR/scripts/control.sh togglePlayPause"
  tmux bind-key "$key_next" run-shell "$CURRENT_DIR/scripts/control.sh next"
  tmux bind-key "$key_prev" run-shell "$CURRENT_DIR/scripts/control.sh previous"
  tmux bind-key "$key_seek_forward" run-shell "$CURRENT_DIR/scripts/control.sh seek 10"
  tmux bind-key "$key_seek_backward" run-shell "$CURRENT_DIR/scripts/control.sh seek -10"
}

main() {
  update_tmux_option "status-right"
  update_tmux_option "status-left"
  setup_keybindings
}

main
