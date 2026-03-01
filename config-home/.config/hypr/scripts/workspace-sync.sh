#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"
workspace="${2:-}"

if [[ -z "$action" ]]; then
  exit 1
fi

case "$action" in
  switch|move|move-silent)
    if [[ -z "$workspace" || ! "$workspace" =~ ^[0-9]+$ ]]; then
      exit 1
    fi
    ;;
  move-monitor-left|move-monitor-right|move-monitor-left-silent|move-monitor-right-silent)
    ;;
  switch-next|switch-prev)
    ;;
  *)
    exit 1
    ;;
esac

if [[ -z "$workspace" ]]; then
  workspace=0
fi

if ! command -v hyprctl >/dev/null 2>&1; then
  exit 1
fi

monitors_json="$(hyprctl -j monitors 2>/dev/null || true)"
if [[ -z "$monitors_json" || "$monitors_json" == "[]" ]]; then
  case "$action" in
    switch)
      hyprctl dispatch workspace "$workspace" >/dev/null 2>&1 || true
      ;;
    move)
      hyprctl dispatch movetoworkspace "$workspace" >/dev/null 2>&1 || true
      ;;
    move-silent)
      hyprctl dispatch movetoworkspacesilent "$workspace" >/dev/null 2>&1 || true
      ;;
    move-monitor-left|move-monitor-right|move-monitor-left-silent|move-monitor-right-silent|switch-next|switch-prev)
      :
      ;;
  esac
  exit 0
fi

mapfile -t monitor_info < <(
  jq -r 'sort_by(.x, .y)[] | [.name, (.focused | tostring)] | @tsv' <<<"$monitors_json"
)

monitor_count="${#monitor_info[@]}"
left_monitor="${monitor_info[0]%%$'\t'*}"
right_monitor="$left_monitor"
focused_monitor="$left_monitor"

if (( monitor_count > 1 )); then
  right_monitor="${monitor_info[1]%%$'\t'*}"
fi

for line in "${monitor_info[@]}"; do
  name="${line%%$'\t'*}"
  focused="${line##*$'\t'}"
  if [[ "$focused" == "true" ]]; then
    focused_monitor="$name"
    break
  fi
done

dispatch() {
  hyprctl dispatch "$@" >/dev/null
}

dispatch_exec() {
  hyprctl dispatch exec "$1" >/dev/null
}

window_address_by_title() {
  local title="$1"
  hyprctl -j clients 2>/dev/null | jq -r --arg title "$title" '.[] | select(.title == $title) | .address' | head -n1
}

window_address_by_filter() {
  local jq_filter="$1"
  hyprctl -j clients 2>/dev/null | jq -r "$jq_filter | .address" | head -n1
}

client_matches() {
  local jq_filter="$1"
  hyprctl -j clients 2>/dev/null | jq -e "$jq_filter" >/dev/null
}

spotify_is_running() {
  client_matches '.[] | select(.class == "spotify")'
}

horizon_client_is_running() {
  client_matches '.[] | select(.class == "Horizon-client")'
}

visualizer_is_running() {
  client_matches '.[] | select(.class == "com.mitchellh.ghostty" and .title == "MusicVisualizer")'
}

pulse_is_running() {
  client_matches '.[] | select(.title == "MusicPulse")'
}

lyrics_panel_is_running() {
  client_matches '.[] | select(.title == "MusicLyrics")'
}

dashboard_panel_is_running() {
  client_matches '.[] | select(.class == "com.mitchellh.ghostty" and .title == "MusicDashboard")'
}

gmail_is_running() {
  client_matches '.[] | select(.title | test("gmail|inbox"; "i"))'
}

whatsapp_is_running() {
  client_matches '.[] | select(.title | test("whatsapp"; "i"))'
}

discord_is_running() {
  client_matches '.[] | select(.class | test("^discord$"; "i"))'
}

research_chat_is_running() {
  client_matches '.[] | select(.workspace.id == 8 and (.title | test("chatgpt"; "i")))'
}

move_existing_research_chat_to_workspace() {
  local address

  address="$(window_address_by_filter '.[] | select(.title | test("chatgpt"; "i"))')"
  if [[ -z "$address" || "$address" == "null" ]]; then
    return 1
  fi

  dispatch movetoworkspacesilent "8,address:${address}"
  return 0
}

research_codex_is_running() {
  client_matches '.[] | select(.class == "com.mitchellh.ghostty" and .title == "ResearchCodex")'
}

sync_workspace_pair() {
  local base_workspace="$1"

  if (( base_workspace >= 1 && base_workspace <= 10 )) && (( monitor_count > 1 )); then
    dispatch focusmonitor "$left_monitor"
    dispatch workspace "$base_workspace"
    dispatch focusmonitor "$right_monitor"
    dispatch workspace "$((base_workspace + 100))"
    dispatch focusmonitor "$focused_monitor"
  else
    dispatch workspace "$base_workspace"
  fi
}

delayed_sync_workspace_pair() {
  local base_workspace="$1"

  (
    sleep 2
    if [[ "$(resolve_mirrored_base_workspace)" == "$base_workspace" ]]; then
      sync_workspace_pair "$base_workspace"
    fi
    sleep 3
    if [[ "$(resolve_mirrored_base_workspace)" == "$base_workspace" ]]; then
      sync_workspace_pair "$base_workspace"
    fi
  ) >/dev/null 2>&1 &
}

launch_spotify_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 10 )); then
    return 1
  fi

  if spotify_is_running; then
    return 1
  fi

  setsid uwsm-app -- spotify >/dev/null 2>&1 &
  return 0
}

launch_horizon_client_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 7 )); then
    return 1
  fi

  if ! command -v horizon-client-omarchy >/dev/null 2>&1; then
    return 1
  fi

  if horizon_client_is_running; then
    return 1
  fi

  setsid uwsm-app -- horizon-client-omarchy --allmonitors --desktopSize=all >/dev/null 2>&1 &
  return 0
}

launch_visualizer_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 10 )); then
    return 1
  fi

  if ! command -v cava >/dev/null 2>&1; then
    return 1
  fi

  if visualizer_is_running; then
    return 1
  fi

  setsid uwsm-app -- ghostty --title=MusicVisualizer -e ~/.local/bin/music-control-room-cava >/dev/null 2>&1 &
  return 0
}

layout_pulse_window() {
  local pulse_address
  local floating

  for _ in $(seq 1 25); do
    pulse_address="$(window_address_by_title "MusicPulse")"
    if [[ -n "$pulse_address" && "$pulse_address" != "null" ]]; then
      floating="$(hyprctl -j clients 2>/dev/null | jq -r --arg addr "$pulse_address" '.[] | select(.address == $addr) | (.floating | tostring)')"
      dispatch focuswindow "address:$pulse_address"
      if [[ "$floating" != "true" ]]; then
        dispatch togglefloating
      fi
      dispatch resizeactive exact 804 280
      dispatch moveactive exact 1104 38
      return
    fi
    sleep 0.2
  done
}

layout_lyrics_window() {
  local lyrics_address
  local floating

  for _ in $(seq 1 25); do
    lyrics_address="$(window_address_by_title "MusicLyrics")"
    if [[ -n "$lyrics_address" && "$lyrics_address" != "null" ]]; then
      floating="$(hyprctl -j clients 2>/dev/null | jq -r --arg addr "$lyrics_address" '.[] | select(.address == $addr) | (.floating | tostring)')"
      dispatch focuswindow "address:$lyrics_address"
      if [[ "$floating" != "true" ]]; then
        dispatch togglefloating
      fi
      dispatch resizeactive exact 804 500
      dispatch moveactive exact 1104 330
      return
    fi
    sleep 0.2
  done
}

ensure_control_room_server() {
  if pgrep -f 'music-control-room-server' >/dev/null 2>&1; then
    return
  fi

  setsid ~/.local/bin/music-control-room-server >/tmp/music-control-room.log 2>&1 &
  sleep 0.2
}

launch_pulse_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 10 )); then
    return 1
  fi

  if ! command -v chromium >/dev/null 2>&1; then
    return 1
  fi

  if pulse_is_running; then
    return 1
  fi

  ensure_control_room_server
  setsid uwsm-app -- chromium --app=http://127.0.0.1:8976/ >/dev/null 2>&1 &
  layout_pulse_window &
  return 0
}

launch_lyrics_panel_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 10 )); then
    return 1
  fi

  if lyrics_panel_is_running; then
    return 1
  fi

  ensure_control_room_server
  setsid uwsm-app -- chromium --app=http://127.0.0.1:8976/lyrics >/dev/null 2>&1 &
  layout_lyrics_window &
  return 0
}

launch_dashboard_panel_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 10 )); then
    return 1
  fi

  if dashboard_panel_is_running; then
    return 1
  fi

  setsid uwsm-app -- ghostty --title=MusicDashboard -e ~/.local/bin/music-control-room-status >/dev/null 2>&1 &
  return 0
}

launch_command_on_workspace() {
  local target_workspace="$1"
  local command="$2"

  dispatch_exec "[workspace ${target_workspace} silent] ${command}"
}

move_window_to_workspace_when_ready() {
  local jq_filter="$1"
  local target_workspace="$2"
  local address

  for _ in $(seq 1 40); do
    address="$(window_address_by_filter "$jq_filter")"
    if [[ -n "$address" && "$address" != "null" ]]; then
      dispatch movetoworkspacesilent "${target_workspace},address:${address}"
      return 0
    fi
    sleep 0.2
  done

  return 1
}

launch_gmail_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 9 )); then
    return 1
  fi

  if ! command -v omarchy-launch-webapp >/dev/null 2>&1; then
    return 1
  fi

  if gmail_is_running; then
    return 1
  fi

  launch_command_on_workspace 9 'omarchy-launch-webapp "https://mail.google.com/mail/u/0/#inbox"'
  return 0
}

launch_whatsapp_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 9 )); then
    return 1
  fi

  if ! command -v omarchy-launch-webapp >/dev/null 2>&1; then
    return 1
  fi

  if whatsapp_is_running; then
    return 1
  fi

  launch_command_on_workspace 109 'omarchy-launch-webapp "https://web.whatsapp.com/"'
  move_window_to_workspace_when_ready '.[] | select(.class == "chrome-web.whatsapp.com__-Default")' 109 &
  return 0
}

launch_discord_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 9 )); then
    return 1
  fi

  if ! command -v discord >/dev/null 2>&1; then
    return 1
  fi

  if discord_is_running; then
    return 1
  fi

  launch_command_on_workspace 109 "uwsm-app -- discord"
  move_window_to_workspace_when_ready '.[] | select(.class == "discord")' 109 &
  return 0
}

launch_research_chat_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 8 )); then
    return 1
  fi

  if ! command -v omarchy-launch-webapp >/dev/null 2>&1; then
    return 1
  fi

  if research_chat_is_running; then
    return 1
  fi

  if move_existing_research_chat_to_workspace; then
    return 0
  fi

  launch_command_on_workspace 8 'omarchy-launch-webapp "https://chatgpt.com/"'
  return 0
}

launch_research_codex_for_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace != 8 )); then
    return 1
  fi

  if ! command -v ghostty >/dev/null 2>&1; then
    return 1
  fi

  if ! command -v codex >/dev/null 2>&1; then
    return 1
  fi

  if research_codex_is_running; then
    return 1
  fi

  launch_command_on_workspace 108 'uwsm-app -- ghostty --title=ResearchCodex -e ~/.local/bin/research-workspace-codex'
  return 0
}

resolve_numbered_workspace() {
  local requested_workspace="$1"

  if (( requested_workspace >= 1 && requested_workspace <= 10 )); then
    if [[ "$focused_monitor" == "$right_monitor" && "$monitor_count" -gt 1 ]]; then
      printf '%s\n' "$((requested_workspace + 100))"
      return
    fi
  fi

  printf '%s\n' "$requested_workspace"
}

resolve_paired_workspace() {
  local direction="$1"
  local active_workspace

  active_workspace="$(jq -r '.[] | select(.focused == true) | .activeWorkspace.id' <<<"$monitors_json")"
  if ! [[ "$active_workspace" =~ ^[0-9]+$ ]]; then
    exit 1
  fi

  case "$direction" in
    left)
      if (( active_workspace >= 101 && active_workspace <= 110 )); then
        printf '%s\n' "$((active_workspace - 100))"
      else
        printf '%s\n' "$active_workspace"
      fi
      ;;
    right)
      if (( active_workspace >= 1 && active_workspace <= 10 )) && (( monitor_count > 1 )); then
        printf '%s\n' "$((active_workspace + 100))"
      else
        printf '%s\n' "$active_workspace"
      fi
      ;;
    *)
      exit 1
      ;;
  esac
}

resolve_mirrored_base_workspace() {
  local active_workspace

  active_workspace="$(jq -r '.[] | select(.focused == true) | .activeWorkspace.id' <<<"$monitors_json")"
  if ! [[ "$active_workspace" =~ ^[0-9]+$ ]]; then
    exit 1
  fi

  if (( active_workspace >= 101 && active_workspace <= 110 )); then
    printf '%s\n' "$((active_workspace - 100))"
  elif (( active_workspace >= 1 && active_workspace <= 10 )); then
    printf '%s\n' "$active_workspace"
  else
    printf '%s\n' 1
  fi
}

resolve_adjacent_workspace() {
  local direction="$1"
  local current_workspace

  current_workspace="$(resolve_mirrored_base_workspace)"

  case "$direction" in
    next)
      if (( current_workspace == 10 )); then
        printf '%s\n' 1
      else
        printf '%s\n' "$((current_workspace + 1))"
      fi
      ;;
    prev)
      if (( current_workspace == 1 )); then
        printf '%s\n' 10
      else
        printf '%s\n' "$((current_workspace - 1))"
      fi
      ;;
    *)
      exit 1
      ;;
  esac
}

target_workspace="${workspace:-0}"
if [[ "$action" == "switch" || "$action" == "move" || "$action" == "move-silent" ]]; then
  target_workspace="$(resolve_numbered_workspace "$workspace")"
fi

case "$action" in
  switch)
    sync_workspace_pair "$workspace"
    launched_workspace_apps=1
    if launch_research_chat_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if launch_research_codex_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if launch_gmail_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if launch_whatsapp_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if launch_discord_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if launch_horizon_client_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if launch_spotify_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if launch_visualizer_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if launch_pulse_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if launch_lyrics_panel_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if launch_dashboard_panel_for_workspace "$workspace"; then
      launched_workspace_apps=0
    fi
    if (( launched_workspace_apps == 0 )); then
      sleep 0.5
      if [[ "$(resolve_mirrored_base_workspace)" == "$workspace" ]]; then
        sync_workspace_pair "$workspace"
      fi
      sleep 1.0
      if [[ "$(resolve_mirrored_base_workspace)" == "$workspace" ]]; then
        sync_workspace_pair "$workspace"
        delayed_sync_workspace_pair "$workspace"
      fi
    fi
    ;;
  move)
    dispatch movetoworkspace "$target_workspace"
    ;;
  move-silent)
    dispatch movetoworkspacesilent "$target_workspace"
    ;;
  move-monitor-left)
    dispatch movetoworkspace "$(resolve_paired_workspace left)"
    ;;
  move-monitor-right)
    dispatch movetoworkspace "$(resolve_paired_workspace right)"
    ;;
  move-monitor-left-silent)
    dispatch movetoworkspacesilent "$(resolve_paired_workspace left)"
    ;;
  move-monitor-right-silent)
    dispatch movetoworkspacesilent "$(resolve_paired_workspace right)"
    ;;
  switch-next)
    next_workspace="$(resolve_adjacent_workspace next)"
    dispatch focusmonitor "$left_monitor"
    dispatch focusworkspaceoncurrentmonitor "$next_workspace"
    if (( monitor_count > 1 )); then
      dispatch focusmonitor "$right_monitor"
      dispatch focusworkspaceoncurrentmonitor "$((next_workspace + 100))"
    fi
    dispatch focusmonitor "$focused_monitor"
    ;;
  switch-prev)
    prev_workspace="$(resolve_adjacent_workspace prev)"
    dispatch focusmonitor "$left_monitor"
    dispatch focusworkspaceoncurrentmonitor "$prev_workspace"
    if (( monitor_count > 1 )); then
      dispatch focusmonitor "$right_monitor"
      dispatch focusworkspaceoncurrentmonitor "$((prev_workspace + 100))"
    fi
    dispatch focusmonitor "$focused_monitor"
    ;;
  *)
    exit 1
    ;;
esac
