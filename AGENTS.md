# AGENTS

This workspace is used by OpenCode through a Telegram interface.

## Intent

- Operate as a single-user homelab coding agent.
- Use `gh` CLI for GitHub operations (issues, comments, PRs).
- Work inside `/workspace` repos only.

## Safety rules

- Never expose tokens or print secret values.
- Never use destructive git commands (`reset --hard`, force-push) unless explicitly requested.
- Prefer opening pull requests over pushing directly to default branches.
- For risky or irreversible actions, explain plan first and ask for confirmation.

## GitHub defaults

- Read issue and PR context before coding.
- Keep commits focused and small.
- Write concise PR descriptions with intent and testing notes.
