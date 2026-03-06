# OmarchyDotFiles

Personal dotfiles for an Omarchy setup, managed with GNU Stow.

Repo:

```text
https://github.com/CHERAM/OmarchyDotFiles/
```

## Dual Monitor Setup

This repo includes the custom Hyprland and Waybar setup for mirrored workspaces across two monitors.

Behavior:

- both monitors show workspaces `1 2 3 4 5 6 7 8 9 0`
- Hyprland mirrors the numbered workspaces across left and right monitors
- `SUPER + 1..0` switches mirrored workspaces
- `SUPER + SHIFT + 1..0` moves a window to a mirrored workspace
- `SUPER + SHIFT + ALT + LEFT/RIGHT` moves a window between monitors on the same workspace number

Files responsible for that behavior:

- `config-home/.config/hypr/workspaces.conf`
- `config-home/.config/hypr/scripts/workspace-sync.sh`
- `config-home/.config/waybar/config.jsonc`

## Layout

Managed files live here:

```text
config-home/.config/
config-home/.local/bin/
config-home/.local/share/music-control-room/
```

Stow links them into:

```text
~/.config/
~/.local/bin/
~/.local/share/music-control-room/
```

## Workspace 0 Music Control Room

Workspace `0` / `10` is customized as a music workspace:

- left monitor workspace `10` launches a music control room
- right monitor workspace `110` launches Spotify
- `SUPER + SHIFT + M` jumps directly to that workspace

Left-side control room panes:

- `MusicVisualizer`: main `cava` visualizer in Ghostty
- `MusicPulse`: browser-based secondary visualizer
- `MusicLyrics`: browser-based lyrics pane
- `MusicDashboard`: compact now-playing dashboard

Files responsible for that behavior:

- `config-home/.config/hypr/hyprland.conf`
- `config-home/.config/hypr/bindings.conf`
- `config-home/.config/hypr/scripts/workspace-sync.sh`
- `config-home/.local/bin/music-control-room-cava`
- `config-home/.local/bin/music-control-room-server`
- `config-home/.local/bin/music-control-room-status`
- `config-home/.local/share/music-control-room/index.html`
- `config-home/.local/share/music-control-room/lyrics.html`
- `config-home/.config/cava/config`

## Workspace 8 Research + Codex

Workspace `8` / `108` is customized as a research workspace:

- left monitor workspace `8` launches ChatGPT for research
- right monitor workspace `108` launches a dedicated Ghostty terminal running `codex`
- Waybar shows workspace `8` and `108` with the search icon ``

The Codex terminal launcher defaults to `~/dotfiles` and falls back to `$HOME`.
Set `CODEX_WORKSPACE_DIR` if you want a different starting directory.

Files responsible for that behavior:

- `config-home/.config/hypr/scripts/workspace-sync.sh`
- `config-home/.config/waybar/config.jsonc`
- `config-home/.local/bin/research-workspace-codex`

## Workspace 9 Communications Room

Workspace `9` / `109` is customized as a communications workspace:

- left monitor workspace `9` is the communications anchor workspace
- right monitor workspace `109` is used for secondary communications apps
- Waybar shows workspace `9` and `109` with the communications icon ``

On the first visit to workspace `9`, the workspace sync script can launch:

- Gmail on workspace `9` via `omarchy-launch-webapp`
- WhatsApp Web on workspace `109` via `omarchy-launch-webapp`
- Discord on workspace `109` via `uwsm-app -- discord`

Files responsible for that behavior:

- `config-home/.config/hypr/scripts/workspace-sync.sh`
- `config-home/.config/waybar/config.jsonc`
- `workspace-9-communications-plan.md`

## Setup

Install dependencies:

```bash
sudo pacman -S stow git
```

Clone the repo:

```bash
git clone https://github.com/CHERAM/OmarchyDotFiles.git ~/dotfiles
cd ~/dotfiles
```

Apply the symlinks:

```bash
stow --target="$HOME" -d ~/dotfiles config-home
```

## Making Changes

Edit the files inside the repo:

```bash
$EDITOR ~/dotfiles/config-home/.config/hypr/workspaces.conf
$EDITOR ~/dotfiles/config-home/.config/hypr/scripts/workspace-sync.sh
$EDITOR ~/dotfiles/config-home/.config/waybar/config.jsonc
```

Then commit and push:

```bash
cd ~/dotfiles
git status
git add .
git commit -m "Describe the change"
git push
```

## Add A New Config File

Copy the file into the matching path inside `config-home/.config/`, then re-run:

```bash
stow --target="$HOME" -d ~/dotfiles config-home
```

Then commit:

```bash
cd ~/dotfiles
git add .
git commit -m "Add new config file"
git push
```

## Useful Commands

Re-apply symlinks:

```bash
stow --target="$HOME" -d ~/dotfiles config-home
```

Remove symlinks:

```bash
stow -D --target="$HOME" -d ~/dotfiles config-home
```

Check where a live file points:

```bash
readlink -f ~/.config/hypr/workspaces.conf
readlink -f ~/.local/bin/omarchy-launch-code
readlink -f ~/.local/bin/music-control-room-server
readlink -f ~/.local/share/music-control-room/index.html
```

Reload after Hyprland/Waybar changes:

```bash
omarchy-restart-hyprctl
omarchy-restart-waybar
```

## Notes

- Omarchy defaults live under `~/.local/share/omarchy/default/`
- this repo is for local overrides only
- tmux split bindings are customized in `config-home/.config/tmux/tmux.conf`: `|` for horizontal split and `-` for vertical split
- custom launcher overrides can live in `~/.local/bin/`; bind them explicitly if Omarchy's bin appears earlier in `PATH`
- avoid tracking large app-state folders like Chromium or VS Code backups
