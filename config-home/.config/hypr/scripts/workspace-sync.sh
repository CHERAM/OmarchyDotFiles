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
    move-monitor-left|move-monitor-right|move-monitor-left-silent|move-monitor-right-silent)
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

target_workspace="$(resolve_numbered_workspace "$workspace")"

case "$action" in
  switch)
    if (( workspace >= 1 && workspace <= 10 )) && (( monitor_count > 1 )); then
      dispatch focusmonitor "$left_monitor"
      dispatch focusworkspaceoncurrentmonitor "$workspace"
      dispatch focusmonitor "$right_monitor"
      dispatch focusworkspaceoncurrentmonitor "$((workspace + 100))"
      dispatch focusmonitor "$focused_monitor"
    else
      dispatch workspace "$workspace"
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
  *)
    exit 1
    ;;
esac
