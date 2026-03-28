# Phase 2 Audit

## Directly Migrated

- `cli/.npmrc`
  - Only contains mirror registry configuration.
- `cli/.condarc`
  - Contains public mirror configuration and basic conda preferences.
- `docker/.docker/daemon.json`
  - No login state detected.
- `cli/.config/mihomo/config.yaml`
  - Current file only contains a local port setting.
- `cli/.config/cronboard/config.toml`
  - Only contains theme preference.
- `cli/.config/zotero-mcp/config.json`
  - Only contains local semantic search settings.

## Templated

- `git/.gitconfig`
  - Replaced user identity and signing key with placeholders.
- `ai/.claude/settings.json.example`
  - Replaced auth token and proxy endpoint with placeholders.
- `ai/.claude/.ccg/config.toml.example`
  - Replaced machine-specific absolute paths with `{$HOME}` placeholders.
- `ai/.codex/config.toml.example`
  - Replaced API tokens, local trusted paths, and service endpoints with placeholders.
- `cli/.config/kaku/assistant.toml.example`
  - Replaced API key with environment placeholder.
- `ssh/.ssh/config.example`
  - Added a generic template instead of committing real hosts and key paths.

## Intentionally Not Migrated

- `.claude.json`
  - Appears to be runtime state / feature cache, not stable config.
- `.docker/config.json`
  - No auth entries now, but includes local context and desktop-specific state.
- `.config/fish/fish_variables`
  - State-oriented file; not a good default candidate for dotfiles.
- Real `.ssh/config`
  - Contains internal IPs, server aliases, usernames, and private key filenames.
- Real `.claude/settings.json`
  - Contains a live token.
- Real `.codex/config.toml`
  - Contains live service tokens and local trusted path declarations.
- Real `.config/kaku/assistant.toml`
  - Contains a live API key.

## Follow-up Risks

- `editor/.vscode/extensions/extensions.json`
  - Contains absolute local extension install paths under `/Users/skyang/.vscode/extensions`.
  - It is not secret, but it is machine-specific state and may be worth replacing later with a cleaner export.
