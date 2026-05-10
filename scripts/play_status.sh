#!/usr/bin/env bash

MAX_TITLE_LENGTH=30

get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value
  option_value=$(tmux show-option -gqv "$option" 2>/dev/null)
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

truncate_string() {
  local str="$1"
  local max_len="$2"
  if [ ${#str} -gt "$max_len" ]; then
    echo "${str:0:$((max_len - 1))}…"
  else
    echo "$str"
  fi
}

format_time() {
  local seconds="$1"
  if [ -z "$seconds" ] || [ "$seconds" = "null" ] || [ "$seconds" = "" ]; then
    echo "--:--"
    return
  fi
  seconds="${seconds%.*}"
  local minutes=$((seconds / 60))
  local secs=$((seconds % 60))
  printf "%d:%02d" "$minutes" "$secs"
}

main() {
  local max_length
  max_length=$(get_tmux_option "@play_status_max_length" "$MAX_TITLE_LENGTH")

  if ! command -v nowplaying-cli &>/dev/null; then
    echo ""
    return
  fi

  local info
  info=$(nowplaying-cli get title artist playbackRate duration elapsedTime mediaType 2>/dev/null)

  if [ -z "$info" ]; then
    echo ""
    return
  fi

  local title artist playback_rate duration elapsed media_type
  title=$(echo "$info" | sed -n '1p')
  artist=$(echo "$info" | sed -n '2p')
  playback_rate=$(echo "$info" | sed -n '3p')
  duration=$(echo "$info" | sed -n '4p')
  elapsed=$(echo "$info" | sed -n '5p')
  media_type=$(echo "$info" | sed -n '6p')

  if [ -z "$title" ] || [ "$title" = "null" ] || [ "$title" = "None" ]; then
    echo ""
    return
  fi

  # Status symbol
  local status_symbol
  if [ "$playback_rate" = "0" ] || [ "$playback_rate" = "0.0" ]; then
    status_symbol="⏸"
  else
    status_symbol="▶"
  fi

  # Media type symbol
  local type_symbol
  case "$media_type" in
  *video* | *Video* | *movie* | *Movie*)
    type_symbol="🎦"
    ;;
  *)
    type_symbol="♫"
    ;;
  esac

  # Format title (with artist if available)
  local display_title
  if [ -n "$artist" ] && [ "$artist" != "null" ] && [ "$artist" != "None" ]; then
    display_title="$artist - $title"
  else
    display_title="$title"
  fi
  display_title=$(truncate_string "$display_title" "$max_length")

  # Format time
  local elapsed_fmt duration_fmt time_display
  elapsed_fmt=$(format_time "$elapsed")
  duration_fmt=$(format_time "$duration")
  time_display="$elapsed_fmt/$duration_fmt"

  echo "$status_symbol $type_symbol $display_title [$time_display]"
}

main
