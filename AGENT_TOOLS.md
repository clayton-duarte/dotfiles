# AI Agent CLI Tooling

Personal notes on the CLIs I want my AI agents (Copilot Chat Agent Mode,
Claude Code, etc.) to reach for. Scoped to two specific things I actually
do — nothing else.

## The two workflows

### 1. Debug production errors

When something's on fire, the agent should walk me through it using:

- `kubectl --context prod get pods,events -n <ns>` — pod state
- `kubectl --context prod logs -n <ns> <pod> --tail=200` — pod logs
- `logcli query '{service="<name>"} |= "error"' --since=1h` — Loki logs
  across pods (Trailblazer uses the same tool)
- `gcloud logging read '<query>' --limit=50` — Cloud Functions / Cloud Run
- Sentry MCP (already in `mcp.json`) — issue detail and recent events

### 2. Monitor code deployments

After merging, the agent should walk me through what's actually running:

- `gh run list --repo <repo> --limit=10` — CI status
- `gh run view <id> --log-failed` — dig into a failure
- `kubectl --context <env> rollout status deploy/<name>` — deploy progress
- `kubectl --context <env> get canary <name>` — Flagger canary status

## What to install

Add to [packages.json](./packages.json) with per-OS mappings:

- `kubectl`
- `google-cloud-sdk` (provides `gcloud`)
- `logcli` (Homebrew tap `grafana/grafana` on macOS; direct download on Linux)

`gh` is already there. Sentry is already in `mcp.json`.

## One-time auth

- `gcloud auth login && gcloud auth application-default login`
- `kubectl config get-contexts` — should list prod/staging/dev; if not,
  ask platform team for kubeconfig
- `gh auth status` — already handled via `op` shell-plugin
- Grafana/Loki creds for `logcli` — `GRAFANA_URL` + `GRAFANA_TOKEN` from
  `op://Private/Environment/*`, wired into `secrets.zsh`

## Prereqs

- VPN (GlobalProtect) required for `kubectl`, `logcli`, and anything
  hitting internal endpoints

