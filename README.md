# Dotfiles

This repository stores the configs under the repository root and uses
package-style directories so they can be linked back into `$HOME`.

## Current Layout

- `zsh/`, `bash/`, `tmux/`, `vim/`
- `git/`, `aerospace/`, `terminal/`, `cli/`, `fish/`
- `editor/`, `ai/`, `docker/`, `ssh/`
- `MIGRATION_CHECKLIST.md` records the migration plan.
- `PHASE2_AUDIT.md` records which sensitive files were migrated directly,
  templated, or intentionally left local.

## Symlink Policy

The repository is the source of truth for migrated configs.

Managed files are linked back to their original paths under `$HOME`, for
example:

- `zsh/.zshrc` -> `~/.zshrc`
- `terminal/.config/ghostty/config` -> `~/.config/ghostty/config`
- `cli/.config/yazi/yazi.toml` -> `~/.config/yazi/yazi.toml`
- `ai/.claude/CLAUDE.md` -> `~/.claude/CLAUDE.md`

This is intentional. If a config has been migrated, edit the file in this
repository, not the path under `$HOME`.

## Sensitive Files

Some files are intentionally not linked from the repository:

- `~/.gitconfig`
- `~/.ssh/config`
- `~/.claude/settings.json`
- `~/.codex/config.toml`
- `~/.config/kaku/assistant.toml`
- `~/.vscode/extensions/extensions.json`

These either contain secrets, internal hosts, machine-specific trust settings,
or should stay as local runtime state.

Where useful, this repository keeps sanitized templates instead:

- `git/.gitconfig`
- `ssh/.ssh/config.example`
- `ai/.claude/settings.json.example`
- `ai/.claude/.ccg/config.toml.example`
- `ai/.codex/config.toml.example`
- `cli/.config/kaku/assistant.toml.example`

## Backup Rule

Before replacing an original file with a symlink, move the old file into a
backup directory under:

```text
~/.dotfiles-backup-YYYYMMDD-HHMMSS/
```

Do not delete a backup until the linked setup has been stable for a while.

## New Machine Restore

Clone the repository, then run:

```bash
./scripts/bootstrap.sh
```

Useful flags:

```bash
./scripts/bootstrap.sh --dry-run
./scripts/bootstrap.sh --home /tmp/dotfiles-test-home
./scripts/bootstrap.sh --backup ~/.dotfiles-backup-bootstrap
```

What the script does:

- walks the managed package directories
- backs up any existing target file before replacing it
- links real managed configs back into `$HOME`
- skips `.example` files, sensitive templates, and runtime state that should
  stay local

What it does not do:

- it does not overwrite local secret-bearing files with templates
- it does not install tools or applications automatically

After running it on a new machine, review and materialize the local-only
templates you actually need:

- [`git/.gitconfig`](git/.gitconfig)
- [`ssh/.ssh/config.example`](ssh/.ssh/config.example)
- [`ai/.claude/settings.json.example`](ai/.claude/settings.json.example)
- [`ai/.claude/.ccg/config.toml.example`](ai/.claude/.ccg/config.toml.example)
- [`ai/.codex/config.toml.example`](ai/.codex/config.toml.example)
- [`cli/.config/kaku/assistant.toml.example`](cli/.config/kaku/assistant.toml.example)

Then install packages separately if needed:

```bash
brew bundle --file cli/.config/brewfile/Brewfile
```

If you want the same VS Code extension set on a new machine, install from the
portable manifest instead of restoring the runtime state file:

```bash
./scripts/install-vscode-extensions.sh
```

If you use a different compatible editor CLI, point the script at it:

```bash
./scripts/install-vscode-extensions.sh --code-bin cursor
```

The manifest lives at
[`editor/.vscode/extensions/extensions.list`](editor/.vscode/extensions/extensions.list).
The legacy runtime snapshot `editor/.vscode/extensions/extensions.json` is
intentionally excluded from this public repository and remains local-only.
It is not linked by `bootstrap.sh` on new machines.

## Re-linking

If a migrated file is accidentally replaced by a plain file, restore the link
from the repo instead of editing the home-directory copy by hand.

Example:

```bash
DOTFILES_ROOT="$HOME/dotfiles"
mv ~/.zshrc ~/.dotfiles-backup-manual/.zshrc
ln -s "$DOTFILES_ROOT/zsh/.zshrc" ~/.zshrc
```

For nested config paths, create the parent directory first if needed:

```bash
mkdir -p ~/.config/ghostty
ln -s "$DOTFILES_ROOT/terminal/.config/ghostty/config" ~/.config/ghostty/config
```

## Restore Rule

If a linked config causes issues, remove the symlink and restore the backup:

```bash
rm ~/.zshrc
cp ~/.dotfiles-backup-<timestamp>/.zshrc ~/.zshrc
```

For sensitive files, keep using the local real file unless you explicitly
decide to instantiate a template.
