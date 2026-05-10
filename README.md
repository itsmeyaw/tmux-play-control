# tmux-play-status

A tmux plugin that displays the current media playback status in your status bar (macOS).

Shows: play/pause state, media type, artist - title, and elapsed/duration time.

## Example output

```
▶ ♫ Daft Punk - Get Lucky [2:35/6:09]
⏸ 🎬 The Matrix [1:23:45/2:16:30]
```

## Requirements

- macOS
- [nowplaying-cli](https://github.com/kirtan-shah/nowplaying-cli): `brew install nowplaying-cli`

## Installation

### With [TPM](https://github.com/tmux-plugins/tpm)

Add to your `.tmux.conf`:

```tmux
set -g @plugin 'itsmeyaw/tmux-play-status'
```

Then press `prefix + I` to install.

### Manual

```bash
git clone https://github.com/itsmeyaw/tmux-play-status ~/.tmux/plugins/tmux-play-status
```

Add to `.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-play-status/play_status.tmux
```

## Usage

Add `#{play_status}` to your `status-right` or `status-left` in `.tmux.conf`:

```tmux
set -g status-right "#{play_status}"
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `@play_status_max_length` | `30` | Max characters for artist - title before truncation |

Example:

```tmux
set -g @play_status_max_length 40
```

## Playback Controls

The plugin binds keys (prefixed with `prefix +`) for media control:

| Key | Action | Option to customize |
|-----|--------|---------------------|
| `P` | Toggle play/pause | `@play_status_toggle` |
| `N` | Next track | `@play_status_next` |
| `B` | Previous track | `@play_status_prev` |
| `}` | Seek forward 10s | `@play_status_seek_forward` |
| `{` | Seek backward 10s | `@play_status_seek_backward` |

Example customization:

```tmux
set -g @play_status_toggle 'p'
set -g @play_status_next 'n'
set -g @play_status_prev 'b'
```

## Symbols

| Symbol | Meaning |
|--------|---------|
| ▶ | Playing |
| ⏸ | Paused |
| ♫ | Music |
| 🎬 | Video |
