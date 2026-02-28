# Workspace 9 Communications Room

Design plan for workspace `9` without applying config changes yet.

## Goal

Turn workspace `9` into a dedicated communications room so interruptions stay separated from workspaces `1-6`.

## Primary Apps

- Signal
- Gmail
- WhatsApp Web

## Optional Apps

- Discord
- Telegram

These should stay manual at first unless daily usage justifies auto-launching them.

## Launch Behavior

On the first visit to workspace `9`:

- launch Gmail
- launch Signal
- launch WhatsApp Web

Do not auto-launch Discord or Telegram initially.

## Monitor Preference

Left monitor:

- Gmail as the anchor pane

Right monitor:

- Signal
- WhatsApp Web

Optional later:

- Discord and Telegram can also open on the right side if enabled

## Waybar Identity

Workspace: `9`

Preferred icon:

- `󰍩`

Alternatives:

- `󰭹`
- `󰇮`

Recommended style:

- icon only

## Why This Layout

- Gmail is the highest-density communications tool and deserves the main pane
- Signal and WhatsApp are lighter secondary panes
- keeping communications isolated reduces distraction during focused work
- optional apps stay manual until the workspace proves it needs them

## Future Implementation Notes

Likely files to update when implementing:

- `config-home/.config/hypr/workspaces.conf`
- `config-home/.config/hypr/scripts/workspace-sync.sh`
- `config-home/.config/hypr/hyprland.conf`
- `config-home/.config/waybar/config.jsonc`

Likely behavior to add:

- auto-launch workspace `9` apps on first open
- assign preferred monitor/workspace placement rules
- replace Waybar workspace `9` label with communications icon
