# OpenCode + Telegram + gh (Docker)

Minimal homelab stack for:

- OpenCode server in Docker
- Telegram chat interface via `@grinev/opencode-telegram-bot`
- `gh` CLI available to the agent for issues/comments/PR workflows
- A mounted workspace directory where repos can be cloned and switched

This is intentionally a small "mini OpenClaw" style setup without the full OpenClaw control plane.

## What you get

- `opencode` service: runs `opencode serve` and authenticates `gh` from GitHub App creds or `GH_TOKEN`
- `telegram-bot` service: forwards Telegram prompts to OpenCode over Docker network
- `bun` is installed in the image so the agent can run Bun-based project commands
- Image default command runs both processes in one container for single-container platforms (for example unRAID)
- Persistent state volumes for OpenCode and the bot
- Workspace data at `/workspace` (host bind via `WORKSPACE_DIR` or default named volume)
- No public inbound ports exposed by default

## Prereqs

- Docker Engine + Docker Compose plugin
- Telegram bot token from [@BotFather](https://t.me/BotFather)
- Your Telegram user id from [@userinfobot](https://t.me/userinfobot)
- GitHub credentials for `gh` operations (token or GitHub App)
- At least one OpenCode provider API key

## Quick start

1. Copy env template:

```bash
cp .env.example .env
```

If using GitHub App auth, you can also review/copy values from:

```bash
cat .env.github-app.example
```

2. Edit `.env` and set at least:

- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_ALLOWED_USER_ID`
- `GH_TOKEN` or GitHub App credentials
- model/provider values and matching provider key(s)
- optionally `WORKSPACE_DIR` to use a specific absolute host path
- optionally `GH_CONFIG_DIR` to persist `gh` auth in a host folder (for example `appdata/oc-agent/gh`)

3. Start stack:

```bash
docker compose up -d --build
```

4. Follow logs:

```bash
docker compose logs -f
```

5. Open your Telegram bot and send `/status`.

## unRAID / single-container setup

If you run a single container instead of Docker Compose, use the image default command
(`all-in-one-entrypoint.sh`) so OpenCode server and Telegram bridge start together.

Recommended container paths:

- `/workspace` -> host folder for repos (your project files)
- `/home/opencode` -> host folder for persistent OpenCode/bot state

If these are not mapped, Docker creates managed volumes for both paths by default.

Required env vars:

- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_ALLOWED_USER_ID`

Recommended env vars:

- `GITHUB_APP_ID`, `GITHUB_APP_INSTALLATION_ID`, `GITHUB_APP_PRIVATE_KEY_B64` (or `GH_TOKEN`)
- `BOT_GIT_NAME`, `BOT_GIT_EMAIL`

Notes:

- `OPENCODE_API_URL` defaults to `http://127.0.0.1:4096` in single-container mode.
- `WORKSPACE_DIR` is only used by `docker-compose.yml`; in unRAID, path mappings control mounts directly.
- Container startup writes `/home/opencode/.config/opencode-telegram-bot/.env` from env vars,
  so the Telegram bot skips the interactive config wizard (no TTY needed).

## GitHub App setup (before first container start)

If you want bot identity instead of your personal account identity, use a GitHub App.

1. Create the app

- Go to GitHub -> `Settings` -> `Developer settings` -> `GitHub Apps` -> `New GitHub App`
- Set any app name (for example `opencode-homelab-bot`)
- Set `Homepage URL` to your repo URL (or any valid URL you control)
- Disable webhooks (not needed for this stack)

2. Set repository permissions

- `Contents`: `Read and write`
- `Pull requests`: `Read and write`
- `Issues`: `Read and write`
- `Metadata`: `Read-only` (default)

3. Create private key

- In app settings, click `Generate a private key`
- Save the downloaded `.pem` file somewhere safe (do not commit it)

4. Install the app on target repos

- In app settings, click `Install App`
- Choose account/org and install only repositories you want this bot to manage

5. Collect values for `.env`

- `GITHUB_APP_ID`: from the app settings page (`App ID`)
- `GITHUB_APP_INSTALLATION_ID`: from the installation URL (look for `/installations/<id>`)
- `GITHUB_APP_PRIVATE_KEY_B64`: base64 of the `.pem` private key

6. Put values in `.env` (repo root)

You can copy this block from `.env.github-app.example`.

```env
GITHUB_APP_ID=123456
GITHUB_APP_INSTALLATION_ID=78901234
GITHUB_APP_PRIVATE_KEY_B64=<base64-of-your-pem>

BOT_GIT_NAME=OpenCode Bot
BOT_GIT_EMAIL=opencode-bot@users.noreply.github.com
```

Base64 helpers:

```bash
# macOS/Linux
base64 < github-app-private-key.pem | tr -d '\n'
```

```powershell
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("github-app-private-key.pem"))
```

7. Start containers

```bash
docker compose up -d --build
```

8. Verify auth inside runtime

```bash
docker compose exec opencode gh auth status
docker compose exec opencode gh api repos/OWNER/REPO
```

Tip: for git pushes with token-based auth, repo remotes should be HTTPS (not SSH).

## Workspace model

`/workspace` is always mounted in the `opencode` container.

- If `WORKSPACE_DIR` is set, Compose uses that host path.
- If `WORKSPACE_DIR` is not set, Compose uses a persistent named volume `workspace`.
- Service entrypoints explicitly `cd` into `/workspace` (or `OPENCODE_WORKSPACE_ROOT` if set)
  so sessions default there instead of `/`.

`gh` config is also mounted to `/home/opencode/.config/gh` by default via:

- `GH_CONFIG_DIR` if set
- otherwise `appdata/oc-agent/gh`

Clone repos either on host into that folder, or from inside container:

```bash
docker compose exec opencode git clone https://github.com/OWNER/REPO.git /workspace/REPO
```

Then switch projects in Telegram with `/projects`.

## Useful commands

```bash
# service status
docker compose ps

# bot logs only
docker compose logs -f telegram-bot

# opencode logs only
docker compose logs -f opencode

# test gh auth inside runtime
docker compose exec opencode gh auth status

# list issues from inside runtime
docker compose exec opencode gh issue list -R OWNER/REPO
```

## GitHub identity options

You can run this stack without your personal GitHub account credentials.

### Option A: GitHub App (recommended)

Configure these env vars in `.env`:

- `GITHUB_APP_ID`
- `GITHUB_APP_INSTALLATION_ID`
- `GITHUB_APP_PRIVATE_KEY` (or `GITHUB_APP_PRIVATE_KEY_B64`)

At startup, `opencode` mints an installation token and exports it as `GH_TOKEN`. The image also wraps `gh` so each `gh` command refreshes the token automatically when GitHub App credentials are present. See the full setup walkthrough above.

Typical GitHub App permissions for this workflow:

- Repository permissions: `Contents` (Read/Write), `Pull requests` (Read/Write), `Issues` (Read/Write), `Metadata` (Read)
- Install the app only on repos you want the bot to touch

Result:

- API actions (issues/comments/PR operations) are performed as your app/bot identity.
- No personal PAT is required.

Note: for branch pushes with app tokens, repos should use HTTPS remotes (not SSH).

Optional commit identity override (recommended):

- `BOT_GIT_NAME=OpenCode Bot`
- `BOT_GIT_EMAIL=opencode-bot@users.noreply.github.com`

These are exported as `GIT_AUTHOR_*` and `GIT_COMMITTER_*` for commands run by OpenCode,
so commit metadata uses your bot name/email without writing git config files.

### Option B: Personal token

Set `GH_TOKEN` with repo read/write scopes.

Result:

- Actions run as your account identity.

## GitHub Actions build

This repo includes `/.github/workflows/docker-image.yml` to build this image in GitHub Actions.

- On pushes to `main`: builds and pushes multi-arch image to GHCR

Published image name:

```text
ghcr.io/<owner>/<repo>
```

Common tags produced:

- `latest` (default branch)
- `main`
- `sha-<commit>`

If package publishing is blocked, verify repository settings allow GitHub Actions to write packages.

## Security notes

- Bot access is restricted to `TELEGRAM_ALLOWED_USER_ID`.
- Keep `.env` private (contains bot and GitHub tokens).
- Mount only directories you want the agent to access.
- This setup uses full read/write GitHub credentials by design per your requirement.

## Files

- `docker-compose.yml`: service topology, healthchecks, volumes
- `docker/Dockerfile`: runtime image with `opencode`, `opencode-telegram`, `gh`, `bun`
- `docker/opencode-entrypoint.sh`: `gh` login + OpenCode server startup
- `docker/telegram-bot-entrypoint.sh`: startup checks + bot launch
