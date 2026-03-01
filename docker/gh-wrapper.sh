#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${GITHUB_APP_ID:-}" ]] && [[ -n "${GITHUB_APP_INSTALLATION_ID:-}" ]] && [[ -n "${GITHUB_APP_PRIVATE_KEY:-${GITHUB_APP_PRIVATE_KEY_B64:-}}" ]]; then
  export GH_TOKEN="$(node /usr/local/bin/github-app-token.mjs)"
fi

exec /usr/bin/gh "$@"
