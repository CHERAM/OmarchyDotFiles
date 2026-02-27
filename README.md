# OmarchyDotFiles

Personal dotfiles for an Omarchy-based setup, managed with GNU Stow.

This repository stores selected files from `~/.config` and symlinks them into place. The goal is to keep local overrides versioned without committing large app state, caches, browser profiles, or generated junk.

Repository URL:

```text
https://github.com/CHERAM/OmarchyDotFiles/
```

## What This Repo Manages

This repo currently tracks selected config files for:

- Hyprland
- Waybar

The tracked files live under:

```text
config-home/.config/
```

Example:

```text
config-home/.config/hypr/workspaces.conf
config-home/.config/hypr/scripts/workspace-sync.sh
config-home/.config/waybar/config.jsonc
```

When Stow is applied, these become symlinks in:

```text
~/.config/
```

## Why Stow

GNU Stow keeps the repo separate from the live config directory and creates symlinks into `$HOME`.

That means:

- the repository stays clean and portable
- live config files still appear in the normal locations apps expect
- Git history is kept in one dedicated repo

## Requirements

Install:

```bash
sudo pacman -S stow git
```

## Clone The Repo

Clone into your home directory:

```bash
git clone https://github.com/CHERAM/OmarchyDotFiles.git ~/dotfiles
cd ~/dotfiles
```

## Repository Layout

The active Stow package is:

```text
config-home/
  .config/
    hypr/
    waybar/
```

Stow maps:

```text
~/dotfiles/config-home/.config/...
```

to:

```text
~/.config/...
```

## First-Time Setup

Before stowing, back up any existing live files that would conflict.

Example:

```bash
mkdir -p ~/.config-backup/hypr/scripts ~/.config-backup/waybar
mv ~/.config/hypr/workspaces.conf ~/.config-backup/hypr/ 2>/dev/null || true
mv ~/.config/hypr/scripts/workspace-sync.sh ~/.config-backup/hypr/scripts/ 2>/dev/null || true
mv ~/.config/waybar/config.jsonc ~/.config-backup/waybar/ 2>/dev/null || true
```

Then apply the symlinks:

```bash
stow --target="$HOME" -d ~/dotfiles config-home
```

## Daily Workflow

If you want to change a config file, edit the file inside the repo, not a backup copy.

Examples:

```bash
$EDITOR ~/dotfiles/config-home/.config/hypr/workspaces.conf
$EDITOR ~/dotfiles/config-home/.config/hypr/scripts/workspace-sync.sh
$EDITOR ~/dotfiles/config-home/.config/waybar/config.jsonc
```

After editing:

```bash
cd ~/dotfiles
git status
git add .
git commit -m "Describe the change"
git push
```

## If You Make A New Change To Any Managed File

Use this flow:

1. Edit the file under `~/dotfiles/config-home/.config/...`
2. If needed, re-run Stow:
```bash
stow --target="$HOME" -d ~/dotfiles config-home
```
3. Reload the affected app
4. Review the diff
5. Commit and push

Example:

```bash
cd ~/dotfiles
git diff
git add .
git commit -m "Update Hyprland workspace bindings"
git push origin master
```

## If You Accidentally Edit The Live File In `~/.config`

That is usually still fine, because the live file should be a symlink into this repo.

To confirm:

```bash
readlink -f ~/.config/hypr/workspaces.conf
```

If the output points to `~/dotfiles/...`, your change is already in the repo working tree. Just commit it from `~/dotfiles`.

## Adding A New Config File To The Repo

To start tracking another config file:

1. Create the matching path inside `config-home/.config/`
2. Copy the real file into the repo
3. Back up or remove the original file from `~/.config`
4. Re-run Stow
5. Commit the new file

Example:

```bash
mkdir -p ~/dotfiles/config-home/.config/app
cp ~/.config/app/config.toml ~/dotfiles/config-home/.config/app/
mkdir -p ~/.config-backup/app
mv ~/.config/app/config.toml ~/.config-backup/app/
stow --target="$HOME" -d ~/dotfiles config-home
cd ~/dotfiles
git add .
git commit -m "Add app config"
git push
```

## Restow

If symlinks are missing or drifted, re-run:

```bash
stow --target="$HOME" -d ~/dotfiles config-home
```

## Unstow

To remove symlinks managed by this package:

```bash
stow -D --target="$HOME" -d ~/dotfiles config-home
```

This removes the symlinks only. It does not restore backups automatically.

## Reload Services After Changes

Common commands:

```bash
hyprctl reload
omarchy-restart-waybar
```

## Git Workflow

Basic workflow:

```bash
cd ~/dotfiles
git pull --rebase
git status
git add .
git commit -m "Describe the change"
git push
```

Recommended commit style:

```text
hypr: mirror workspaces across monitors
waybar: show 10 workspaces on both monitors
docs: update stow instructions
```

## What Not To Put In This Repo

Do not track:

- browser profiles
- caches
- logs
- backup folders
- app databases
- generated editor state
- machine-specific secrets unless you intentionally want them versioned

Examples of bad candidates:

- `~/.config/chromium`
- `~/.config/Code/Backups`
- `~/.config/Signal`

## Omarchy Notes

Omarchy keeps its defaults separately under:

```text
~/.local/share/omarchy/default/
```

This repository is for local overrides and personal changes, not for Omarchy base files.

## Backup Notes

During migration, previous live files were moved to:

```text
~/.config-backup/
```

You can keep that folder as a safety net or clean it up once you have verified everything works.
