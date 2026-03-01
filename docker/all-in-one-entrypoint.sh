#!/usr/bin/env bash
set -euo pipefail

hostname="${OPENCODE_SERVER_HOSTNAME:-0.0.0.0}"
port="${OPENCODE_SERVER_PORT:-4096}"
workspace_root="${OPENCODE_WORKSPACE_ROOT:-/workspace}"

export OPENCODE_SERVER_HOSTNAME="${hostname}"
export OPENCODE_SERVER_PORT="${port}"
export OPENCODE_WORKSPACE_ROOT="${workspace_root}"

mkdir -p "${workspace_root}"
cd "${workspace_root}"

if [[ -z "${OPENCODE_API_URL:-}" ]]; then
  export OPENCODE_API_URL="http://127.0.0.1:${port}"
fi

shutdown() {
  local exit_code=$?

  trap - INT TERM EXIT

  for pid in "${opencode_pid:-}" "${bot_pid:-}"; do
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" 2>/dev/null || true
    fi
  done

  wait 2>/dev/null || true
  exit "${exit_code}"
}

trap shutdown INT TERM EXIT

/usr/local/bin/opencode-entrypoint.sh &
opencode_pid=$!

/usr/local/bin/telegram-bot-entrypoint.sh &
bot_pid=$!

wait -n "${opencode_pid}" "${bot_pid}"
