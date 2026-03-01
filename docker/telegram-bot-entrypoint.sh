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

runtime_home="${OPENCODE_TELEGRAM_HOME:-${HOME}/.config/opencode-telegram-bot}"
runtime_env_file="${runtime_home}/.env"

export OPENCODE_TELEGRAM_HOME="${runtime_home}"
export OPENCODE_API_URL="${opencode_api_url}"
export OPENCODE_MODEL_PROVIDER="${OPENCODE_MODEL_PROVIDER:-opencode}"
export OPENCODE_MODEL_ID="${OPENCODE_MODEL_ID:-big-pickle}"

mkdir -p "${runtime_home}"

{
  printf 'TELEGRAM_BOT_TOKEN=%s\n' "${TELEGRAM_BOT_TOKEN}"
  printf 'TELEGRAM_ALLOWED_USER_ID=%s\n' "${TELEGRAM_ALLOWED_USER_ID}"
  printf 'OPENCODE_API_URL=%s\n' "${OPENCODE_API_URL}"
  printf 'OPENCODE_MODEL_PROVIDER=%s\n' "${OPENCODE_MODEL_PROVIDER}"
  printf 'OPENCODE_MODEL_ID=%s\n' "${OPENCODE_MODEL_ID}"

  if [[ -n "${BOT_LOCALE:-}" ]]; then
    printf 'BOT_LOCALE=%s\n' "${BOT_LOCALE}"
  fi
} > "${runtime_env_file}"

if [[ ! -f "${runtime_home}/settings.json" ]]; then
  printf '{}\n' > "${runtime_home}/settings.json"
fi

for _ in {1..60}; do
  if curl -fsS "${opencode_api_url}/global/health" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

exec opencode-telegram start
