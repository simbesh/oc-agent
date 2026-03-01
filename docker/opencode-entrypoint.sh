#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${GITHUB_APP_ID:-}" ]] && [[ -n "${GITHUB_APP_INSTALLATION_ID:-}" ]] && [[ -n "${GITHUB_APP_PRIVATE_KEY:-${GITHUB_APP_PRIVATE_KEY_B64:-}}" ]]; then
  export GH_TOKEN="$(node /usr/local/bin/github-app-token.mjs)"
  echo "Using GitHub App installation token for gh commands"
elif [[ -n "${GH_TOKEN:-}" ]]; then
  echo "Using GH_TOKEN for gh commands"
else
  echo "Warning: no GH_TOKEN or GitHub App credentials configured"
fi

if [[ -n "${BOT_GIT_NAME:-}" ]]; then
  export GIT_AUTHOR_NAME="${BOT_GIT_NAME}"
  export GIT_COMMITTER_NAME="${BOT_GIT_NAME}"
fi

if [[ -n "${BOT_GIT_EMAIL:-}" ]]; then
  export GIT_AUTHOR_EMAIL="${BOT_GIT_EMAIL}"
  export GIT_COMMITTER_EMAIL="${BOT_GIT_EMAIL}"
fi

workspace_root="${OPENCODE_WORKSPACE_ROOT:-/workspace}"
mkdir -p "${workspace_root}"
cd "${workspace_root}"

hostname="${OPENCODE_SERVER_HOSTNAME:-0.0.0.0}"
port="${OPENCODE_SERVER_PORT:-4096}"

exec opencode serve --hostname "${hostname}" --port "${port}"
