#!/bin/bash
# Paste clipboard images into terminal AI CLIs.
# Saves clipboard image to /tmp and pastes a file reference into the active window.
# Falls back to normal paste (Shift+Insert) if no image in clipboard.

CLIPBOARD_TYPES=$(wl-paste --list-types 2>/dev/null)

if echo "$CLIPBOARD_TYPES" | grep -q "image/png"; then
    IMAGE_TYPE="image/png"
elif echo "$CLIPBOARD_TYPES" | grep -q "image/jpeg"; then
    IMAGE_TYPE="image/jpeg"
else
    # No image: fall back to normal text paste.
    hyprctl dispatch sendshortcut SHIFT,Insert,activewindow
    exit 0
fi

TIMESTAMP=$(date +%s)
TMPFILE="/tmp/claude_paste_${TIMESTAMP}.png"

wl-paste --type "$IMAGE_TYPE" > "$TMPFILE" 2>/dev/null

if [ ! -s "$TMPFILE" ]; then
    rm -f "$TMPFILE"
    hyprctl dispatch sendshortcut SHIFT,Insert,activewindow
    exit 1
fi

active_class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')

is_terminal=false
case "$active_class" in
    *ghostty*|*Ghostty*|Alacritty|kitty|foot) is_terminal=true ;;
esac

if [ "$is_terminal" != true ]; then
    hyprctl dispatch sendshortcut SHIFT,Insert,activewindow
    exit 0
fi

PASTE_TEXT="${TMPFILE} "

printf '%s' "$PASTE_TEXT" | wl-copy --type text/plain
sleep 0.1
hyprctl dispatch sendshortcut SHIFT,Insert,activewindow
