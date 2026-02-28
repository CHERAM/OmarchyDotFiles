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
```

Stow links them into:

```text
~/.config/
~/.local/bin/
```

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
```

Reload after Hyprland/Waybar changes:

```bash
hyprctl reload
omarchy-restart-waybar
```

## Notes

- Omarchy defaults live under `~/.local/share/omarchy/default/`
- this repo is for local overrides only
- custom launcher overrides can live in `~/.local/bin/`; bind them explicitly if Omarchy's bin appears earlier in `PATH`
- avoid tracking large app-state folders like Chromium or VS Code backups
