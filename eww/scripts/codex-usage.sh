#!/usr/bin/env bash
set -euo pipefail

window="codexusage"

close_popup() {
  eww close "$window" >/dev/null 2>&1 || true
}

update_error() {
  eww update \
    CODEX_USAGE_STATE="Unavailable" \
    CODEX_USAGE_DETAIL="${1:-Could not load account usage}" >/dev/null 2>&1 || true
}

refresh_usage() {
  local read_fd write_fd line response parsed used remaining reset_at duration plan balance resets window_label reset_label

  eww update CODEX_USAGE_STATE="Loading" CODEX_USAGE_DETAIL="Contacting Codex…" >/dev/null 2>&1 || true

  if ! command -v codex >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
    update_error "Codex or Python is not installed"
    return 1
  fi

  coproc CODEX_SERVER { codex app-server --listen stdio:// 2>/dev/null; }
  exec {read_fd}<&"${CODEX_SERVER[0]}"
  exec {write_fd}>&"${CODEX_SERVER[1]}"

  printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"supermachine-polybar","version":"1.0.0"}}}' >&"$write_fd"
  while IFS= read -r -t 8 -u "$read_fd" line; do
    [[ "$line" == *'"id":1'* ]] && break
  done

  printf '%s\n' '{"jsonrpc":"2.0","method":"initialized"}' >&"$write_fd"
  printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"account/rateLimits/read","params":null}' >&"$write_fd"
  response=""
  while IFS= read -r -t 12 -u "$read_fd" line; do
    if [[ "$line" == *'"id":2'* ]]; then
      response="$line"
      break
    fi
  done

  exec {write_fd}>&-
  exec {read_fd}<&-
  kill "$CODEX_SERVER_PID" >/dev/null 2>&1 || true
  wait "$CODEX_SERVER_PID" 2>/dev/null || true

  if [ -z "$response" ]; then
    update_error "Sign in to Codex, then try again"
    return 1
  fi

  parsed="$(python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)["result"]
    limits = data["rateLimits"]
    primary = limits["primary"]
    values = (
        primary["usedPercent"], primary.get("resetsAt") or 0,
        primary.get("windowDurationMins") or 0, limits.get("planType") or "unknown",
        (limits.get("credits") or {}).get("balance") or "—",
        (data.get("rateLimitResetCredits") or {}).get("availableCount", 0),
    )
    print("\t".join(map(str, values)))
except (KeyError, TypeError, ValueError):
    raise SystemExit(1)
' <<<"$response")" || {
    update_error "Codex returned no usage limits"
    return 1
  }
  IFS=$'\t' read -r used reset_at duration plan balance resets <<<"$parsed"
  remaining=$((100 - used))

  case "$duration" in
    300) window_label="5-hour window" ;;
    10080) window_label="Weekly window" ;;
    *) window_label="$((duration / 60))-hour window" ;;
  esac
  if [ "$reset_at" -gt 0 ]; then
    reset_label="$(date -d "@$reset_at" '+%a, %b %-d at %-I:%M %p')"
  else
    reset_label="Not provided"
  fi

  plan="${plan^} plan"
  eww update \
    CODEX_USAGE_STATE="Ready" \
    CODEX_USAGE_DETAIL="Live account limits" \
    CODEX_USAGE_PLAN="$plan" \
    CODEX_USAGE_USED="$used" \
    CODEX_USAGE_REMAINING="$remaining" \
    CODEX_USAGE_WINDOW="$window_label" \
    CODEX_USAGE_RESET="$reset_label" \
    CODEX_USAGE_CREDITS="$balance" \
    CODEX_USAGE_RESETS="$resets" >/dev/null
}

case "${1:-toggle}" in
  toggle)
    if eww active-windows 2>/dev/null | grep -q "^${window}:"; then
      close_popup
    else
      eww open "$window"
      refresh_usage || true
    fi
    ;;
  refresh) refresh_usage ;;
  close) close_popup ;;
esac
