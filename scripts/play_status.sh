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
  max_length=$(get_tmux_option "@play_control_max_length" "$MAX_TITLE_LENGTH")

  if ! command -v nowplaying-cli &>/dev/null || ! command -v jq &>/dev/null; then
    echo ""
    return
  fi

  local raw
  raw=$(nowplaying-cli get-raw 2>/dev/null)

  if [ -z "$raw" ]; then
    echo ""
    return
  fi

  local title artist playback_rate duration elapsed
  title=$(echo "$raw" | jq -r '.kMRMediaRemoteNowPlayingInfoTitle // empty')
  artist=$(echo "$raw" | jq -r '.kMRMediaRemoteNowPlayingInfoArtist // empty')
  playback_rate=$(echo "$raw" | jq -r '.kMRMediaRemoteNowPlayingInfoPlaybackRate // "0"')
  duration=$(echo "$raw" | jq -r '.kMRMediaRemoteNowPlayingInfoDuration // empty')
  elapsed=$(echo "$raw" | jq -r '.kMRMediaRemoteNowPlayingInfoElapsedTime // empty')

  if [ -z "$title" ]; then
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

  # Format title
  local display_title
  if [ -n "$artist" ]; then
    display_title="$artist - $title"
  else
    display_title="$title"
  fi
  display_title=$(truncate_string "$display_title" "$max_length")

  local elapsed_fmt duration_fmt
  elapsed_fmt=$(format_time "$elapsed")
  duration_fmt=$(format_time "$duration")

  echo "$status_symbol ♫ $display_title [$elapsed_fmt/$duration_fmt]"
}

main
