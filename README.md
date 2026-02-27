# Dotfiles

This repository manages selected config files from `/home/che/.config` using GNU Stow.

## Layout

The active Stow package is:

```text
config-home/
  .config/
    hypr/
    waybar/
```

Managed files live in this repository under:

```text
/home/che/dotfiles/config-home/.config/
```

Live config paths in `/home/che/.config/...` are symlinks back to the files in this repo.

## Current Scope

This repo currently manages:

- `~/.config/hypr/*` selected Hyprland override files
- `~/.config/hypr/scripts/workspace-sync.sh`
- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/style.css`

Original files were backed up to:

```text
/home/che/.config-backup/
```

## How Stow Works Here

Stow creates symlinks from this repo into your home directory.

Run this from anywhere:

```bash
stow --target=/home/che -d /home/che/dotfiles config-home
```

That maps:

```text
/home/che/dotfiles/config-home/.config/...
```

to:

```text
/home/che/.config/...
```

## Typical Workflow

Edit the files in the repo, not the backup copy:

```bash
cd /home/che/dotfiles
```

Examples:

```bash
$EDITOR /home/che/dotfiles/config-home/.config/hypr/workspaces.conf
$EDITOR /home/che/dotfiles/config-home/.config/hypr/scripts/workspace-sync.sh
$EDITOR /home/che/dotfiles/config-home/.config/waybar/config.jsonc
```

Then commit changes:

```bash
cd /home/che/dotfiles
git status
git add .
git commit -m "Describe the change"
```

## Adding New Files

To add another config file under `~/.config`:

1. Create the matching path inside `config-home/.config/`
2. Move or copy the real file into this repo
3. Remove or back up the old file from `~/.config`
4. Re-run Stow

Example:

```bash
mkdir -p /home/che/dotfiles/config-home/.config/app
cp /home/che/.config/app/config.toml /home/che/dotfiles/config-home/.config/app/
mv /home/che/.config/app/config.toml /home/che/.config-backup/
stow --target=/home/che -d /home/che/dotfiles config-home
```

## Restowing

If symlinks are removed or drifted, re-run:

```bash
stow --target=/home/che -d /home/che/dotfiles config-home
```

## Unstow

To remove the symlinks created by Stow:

```bash
stow -D --target=/home/che -d /home/che/dotfiles config-home
```

This removes symlinks only. It does not restore backup files automatically.

## Reloading Apps

After changing Hyprland or Waybar:

```bash
hyprctl reload
omarchy-restart-waybar
```

## Notes

- Do not put large app state directories in this repo.
- Prefer tracking curated override files, not full browser or editor profile data.
- Omarchy defaults live separately under `~/.local/share/omarchy/default/`.
- Your local overrides are the files in this repository.
