# Dotfiles

This repository stores package-style configurations under `$HOME/dotfiles` by
default. The bootstrap script links them back into the active user's home
directory and selects the host platform automatically.

## Current Layout

- `zsh/`, `bash/`, `tmux/`, `vim/`
- `git/`, `aerospace/`, `terminal/`, `cli/`, `fish/`
- `editor/`, `ai/`, `docker/`, `ssh/`
- `julia/` contains the shared Julia startup file and project environments;
  only `julia/startup.jl` is linked by bootstrap.
- `MIGRATION_CHECKLIST.md` records the migration plan.
- `PHASE2_AUDIT.md` records which sensitive files were migrated directly,
  templated, or intentionally left local.

## Symlink Policy

The repository is the source of truth for migrated configs.

`bootstrap.sh` links individual files, and applies these boundaries:

- Each package's own top-level `CLAUDE.md`, since every one of them would
  otherwise map to the single target `~/CLAUDE.md` and overwrite the others.
  The managed global rules file `ai/.claude/CLAUDE.md` is nested and still
  linked.
- `.example` templates, runtime snapshots, Julia project environments, and
  macOS-only packages on Linux are not linked automatically.
- Files reached through a directory that is already a symlink into this
  repository, such as `~/.config/yazi/plugins`. Linking those would replace the
  repository's own file with a symlink to itself.

Managed files are linked back to their original paths under the active user's
`$HOME`, for example:

- `zsh/.zshrc` -> `~/.zshrc`
- `terminal/.config/ghostty/config` -> `~/.config/ghostty/config`
- `cli/.config/yazi/yazi.toml` -> `~/.config/yazi/yazi.toml`
- `ai/.claude/CLAUDE.md` -> `~/.claude/CLAUDE.md`
- `julia/startup.jl` -> `~/.julia/config/startup.jl`

This is intentional. If a config has been migrated, edit the file in this
repository, not the path under `$HOME`.

## Shells

Zsh is the login shell; fish is configured to match it so switching between
them does not change behaviour.

`fish/.config/fish/conf.d/` is loaded in alphabetical order before
`config.fish`:

| File | Purpose |
|------|---------|
| `00-path.fish` | optional Homebrew discovery, PATH construction and pruning |
| `10-env.fish` | exported environment variables, node version from nvm's default |
| `15-keybindings.fish` | vi mode (before `20-tools` so tool bindings survive) |
| `20-tools.fish` | zoxide, atuin, fzf, conda |
| `30-aliases.fish` | aliases |
| `40-colors.fish` | syntax highlighting and pager colours |

Autoloaded functions live in `fish/.config/fish/functions/` (`y`, `wrs`).

Fish discovers Homebrew independently because `~/.zprofile` is zsh-only. Kaku,
Powerlevel10k and nvm's shell function are zsh-only by design; fish uses
Starship and resolves nvm's `default` alias to a PATH entry instead.

To make fish selectable as a login shell:

```bash
command -v fish
chsh -s "$(command -v fish)"
```

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

Do not delete the generated backup until the linked setup has been stable for a
while.

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
./scripts/bootstrap.sh --platform linux --dry-run
```

What the script does:

- walks the managed package directories
- backs up any existing target file before replacing it
- links real managed configs back into `$HOME`
- skips `.example` files, Julia project environments, sensitive templates,
  runtime state, and macOS-only packages on Linux

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

Then install packages separately if needed. The Brewfile is macOS/Homebrew
specific; Linux hosts should use their native package manager or an explicit
host profile:

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
The legacy runtime snapshot
[`editor/.vscode/extensions/extensions.json`](editor/.vscode/extensions/extensions.json)
is kept only for current-machine compatibility and is not linked by
`bootstrap.sh` on new machines.

## Re-linking

If a migrated file is accidentally replaced by a plain file, restore the link
from the repo instead of editing the home-directory copy by hand.

Example:

```bash
mv ~/.zshrc ~/.dotfiles-backup-manual/.zshrc
ln -s "$HOME/dotfiles/zsh/.zshrc" ~/.zshrc
```

For nested config paths, create the parent directory first if needed:

```bash
mkdir -p ~/.config/ghostty
ln -s "$HOME/dotfiles/terminal/.config/ghostty/config" ~/.config/ghostty/config
```

## Restore Rule

If a linked config causes issues, remove the symlink and restore the backup:

```bash
rm ~/.zshrc
cp ~/.dotfiles-backup-YYYYMMDD-HHMMSS/.zshrc ~/.zshrc
```

For sensitive files, keep using the local real file unless you explicitly
decide to instantiate a template.
