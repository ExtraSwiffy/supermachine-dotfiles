#!/usr/bin/env bash
set -euo pipefail

mode="${1:-check}"
state_dir="$HOME/.config/eww/state"
status_file="$state_dir/supermachine-update-status"

mkdir -p "$state_dir"

status() {
  printf '%s\n' "$1" > "$status_file"
  eww update SUPERMACHINE_UPDATE_STATUS="$1" >/dev/null 2>&1 || true
}

repo_dir() {
  if [ -n "${SUPERMACHINE_REPO:-}" ] && [ -d "$SUPERMACHINE_REPO/.git" ]; then
    printf '%s\n' "$SUPERMACHINE_REPO"
  elif [ -d "$HOME/supermachine-dotfiles/.git" ]; then
    printf '%s\n' "$HOME/supermachine-dotfiles"
  elif [ -d "$HOME/dotfiles/.git" ]; then
    printf '%s\n' "$HOME/dotfiles"
  else
    return 1
  fi
}

repo="$(repo_dir)" || {
  status "Dotfiles repo not found"
  exit 1
}

case "$mode" in
  check)
    status "Checking GitHub..."
    if ! git -C "$repo" fetch --quiet; then
      status "Update check failed"
      exit 1
    fi

    upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
    if [ -z "$upstream" ]; then
      status "No upstream configured"
      exit 0
    fi

    local_head="$(git -C "$repo" rev-parse HEAD)"
    remote_head="$(git -C "$repo" rev-parse "$upstream")"

    if [ "$local_head" = "$remote_head" ]; then
      status "SuperMachine is up to date"
    else
      status "Update available"
    fi
    ;;
  update)
    status "Opening updater terminal..."
    setsid -f alacritty -e bash -lc '
      set -e
      repo="${SUPERMACHINE_REPO:-}"
      if [ -z "$repo" ]; then
        if [ -d "$HOME/supermachine-dotfiles/.git" ]; then repo="$HOME/supermachine-dotfiles"; else repo="$HOME/dotfiles"; fi
      fi
      mkdir -p "$HOME/.config/eww/state"
      status_file="$HOME/.config/eww/state/supermachine-update-status"
      cd "$repo"
      echo "Updating SuperMachine from $repo"
      if git pull --ff-only && ./install.sh; then
        echo "SuperMachine updated"
        printf "%s\n" "Update complete" > "$status_file"
      else
        echo "Update failed"
        printf "%s\n" "Update failed" > "$status_file"
      fi
      echo
      read -rp "Press Enter to close..."
    ' >/dev/null 2>&1
    ;;
  *)
    status "Unknown update action"
    exit 1
    ;;
esac

