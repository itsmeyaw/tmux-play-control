#!/usr/bin/env bash

MAX_TITLE_LENGTH=30
STATE_FILE="${TMPDIR:-/tmp}/tmux_play_status_state"

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
  # truncate to integer
  seconds="${seconds%.*}"
  local minutes=$((seconds / 60))
  local secs=$((seconds % 60))
  printf "%d:%02d" "$minutes" "$secs"
}

# macOS MediaRemote only snapshots elapsedTime on play/pause/seek events.
# We save that snapshot plus the system timestamp, then interpolate.
save_state() {
  local title="$1" elapsed="$2" rate="$3" ts="$4"
  printf '%s\n%s\n%s\n%s\n' "$title" "$elapsed" "$rate" "$ts" > "$STATE_FILE"
}

load_state() {
  # outputs: saved_title saved_elapsed saved_rate saved_ts
  if [ ! -f "$STATE_FILE" ]; then
    return 1
  fi
  saved_title=$(sed -n '1p' "$STATE_FILE")
  saved_elapsed=$(sed -n '2p' "$STATE_FILE")
  saved_rate=$(sed -n '3p' "$STATE_FILE")
  saved_ts=$(sed -n '4p' "$STATE_FILE")
}

interpolate_elapsed() {
  local elapsed="$1" rate="$2" title="$3"
  local now
  now=$(date +%s)

  if load_state; then
    if [ "$saved_title" = "$title" ]; then
      if [ "$rate" = "0" ]; then
        # Paused — freeze at saved position (reported elapsed is unreliable when null/0)
        echo "$saved_elapsed"
        return
      elif [ "$saved_rate" = "$rate" ]; then
        # Playing, same rate — interpolate forward
        local delta=$(( now - saved_ts ))
        local base="${saved_elapsed%.*}"
        local computed=$(( base + delta ))
        echo "$computed"
        return
      fi
    fi
  fi

  # Track changed or transitioning play state — save new snapshot
  save_state "$title" "${elapsed%.*}" "$rate" "$now"
  echo "${elapsed%.*}"
}

main() {
  local max_length
  max_length=$(get_tmux_option "@play_control_max_length" "$MAX_TITLE_LENGTH")

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

  # null means paused on macOS
  if [ "$playback_rate" = "null" ] || [ -z "$playback_rate" ]; then
    playback_rate="0"
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

  # Interpolate elapsed time since macOS only snapshots it on state changes
  local elapsed_interp
  elapsed_interp=$(interpolate_elapsed "$elapsed" "$playback_rate" "$title")

  # Clamp to duration
  local dur_int="${duration%.*}"
  if [ -n "$dur_int" ] && [ "$elapsed_interp" -gt "$dur_int" ] 2>/dev/null; then
    elapsed_interp="$dur_int"
  fi

  local elapsed_fmt duration_fmt time_display
  elapsed_fmt=$(format_time "$elapsed_interp")
  duration_fmt=$(format_time "$duration")
  time_display="$elapsed_fmt/$duration_fmt"

  echo "$status_symbol $type_symbol $display_title [$time_display]"
}

main
