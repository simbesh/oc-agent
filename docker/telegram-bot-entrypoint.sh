#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
  echo "TELEGRAM_BOT_TOKEN is required"
  exit 1
fi

if [[ -z "${TELEGRAM_ALLOWED_USER_ID:-}" ]]; then
  echo "TELEGRAM_ALLOWED_USER_ID is required"
  exit 1
fi

opencode_api_url="${OPENCODE_API_URL:-http://127.0.0.1:4096}"

for _ in {1..60}; do
  if curl -fsS "${opencode_api_url}/global/health" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

exec opencode-telegram start
