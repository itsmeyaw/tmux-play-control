#!/usr/bin/env bash

if ! command -v nowplaying-cli &>/dev/null; then
  exit 0
fi

command="$1"
shift

case "$command" in
togglePlayPause | play | pause | next | previous)
  nowplaying-cli "$command"
  ;;
seek)
  local_offset="${1:-10}"
  elapsed=$(nowplaying-cli get elapsedTime 2>/dev/null)
  if [ -n "$elapsed" ] && [ "$elapsed" != "null" ]; then
    elapsed="${elapsed%.*}"
    new_pos=$((elapsed + local_offset))
    if [ "$new_pos" -lt 0 ]; then
      new_pos=0
    fi
    nowplaying-cli seek "$new_pos"
  fi
  ;;
esac
