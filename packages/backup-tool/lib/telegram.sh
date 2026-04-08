#!/usr/bin/env bash
# shellcheck shell=bash
# Telegram alert system with exponential back-off.
#
# Alert state is persisted per alert-key so the same alert is not spammed.
# Back-off: first alert at 0, then 2m, 4m, 8m, 16m … capped at 8 h.
# When the condition clears, a recovery message is sent and state is reset.

TELEGRAM_STATE_DIR="${BACKUP_STATE_DIR:-/var/lib/backup-tool}/alerts"
ALERT_MIN_INTERVAL=120   # 2 minutes (first re-alert)
ALERT_MAX_INTERVAL=28800 # 8 hours

# ── Send raw Telegram message ────────────────────────────────────────────────
telegram_send() {
  local token="$1" chat_id="$2" text="$3"
  local url="https://api.telegram.org/bot${token}/sendMessage"
  curl -sf --max-time 10 \
    -X POST "$url" \
    -d chat_id="$chat_id" \
    -d parse_mode="Markdown" \
    -d text="$text" >/dev/null 2>&1
}

# ── Load bot credentials from config ─────────────────────────────────────────
_tg_load_creds() {
  TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-$(cfg_get "$BACKUP_CONF_FILE" telegram_bot_token)}"
  TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-$(cfg_get "$BACKUP_CONF_FILE" telegram_chat_id)}"
}

_tg_enabled() {
  _tg_load_creds
  [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]
}

# ── Stateful alerting with exponential back-off ──────────────────────────────
# alert_key  : unique id for this alert (e.g. "offline:myhost")
# message    : markdown text to send
alert_fire() {
  local alert_key="$1" message="$2"
  _tg_enabled || return 0

  mkdir -p "$TELEGRAM_STATE_DIR"
  local state_file="${TELEGRAM_STATE_DIR}/${alert_key//\//_}"

  local now last_sent interval next_due
  now=$(date +%s)

  if [[ -f "$state_file" ]]; then
    last_sent=$(sed -n '1p' "$state_file")
    interval=$(sed -n '2p' "$state_file")
    next_due=$(( last_sent + interval ))
    if (( now < next_due )); then
      return 0   # too soon, suppress
    fi
    # double the interval
    interval=$(( interval * 2 ))
    (( interval > ALERT_MAX_INTERVAL )) && interval=$ALERT_MAX_INTERVAL
  else
    interval=$ALERT_MIN_INTERVAL
  fi

  if telegram_send "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" "$message"; then
    printf '%s\n%s\n' "$now" "$interval" > "$state_file"
  fi
}

# Called when the condition that triggered the alert has cleared.
alert_resolve() {
  local alert_key="$1" message="$2"
  local state_file="${TELEGRAM_STATE_DIR}/${alert_key//\//_}"
  [[ -f "$state_file" ]] || return 0   # was never fired
  _tg_enabled || { rm -f "$state_file"; return 0; }

  telegram_send "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" "$message" || true
  rm -f "$state_file"
}
