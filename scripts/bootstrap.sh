#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
HOME_DIR="${HOME}"
BACKUP_ROOT=""
DRY_RUN=0

MANAGED_PACKAGES=(
  zsh
  bash
  tmux
  vim
  git
  aerospace
  terminal
  cli
  fish
  editor
  ai
  docker
)

# These files exist in managed package directories but should not be linked
# automatically on a new machine.
SKIP_SOURCES=(
  "git/.gitconfig"
  "editor/.vscode/extensions/extensions.json"
  "editor/.vscode/extensions/extensions.list"
)

TEMPLATE_HINTS=(
  "git/.gitconfig -> ~/.gitconfig"
  "ssh/.ssh/config.example -> ~/.ssh/config"
  "ai/.claude/settings.json.example -> ~/.claude/settings.json"
  "ai/.claude/.ccg/config.toml.example -> ~/.claude/.ccg/config.toml"
  "ai/.codex/config.toml.example -> ~/.codex/config.toml"
  "cli/.config/kaku/assistant.toml.example -> ~/.config/kaku/assistant.toml"
)

usage() {
  cat <<'EOF'
Usage: ./scripts/bootstrap.sh [options]

Link managed dotfiles from this repository back into a target home directory.

Options:
  --home DIR        Restore into DIR instead of $HOME
  --backup DIR      Use DIR for backups instead of ~/.dotfiles-backup-<timestamp>
  --dry-run         Print actions without modifying anything
  -h, --help        Show this help
EOF
}

log() {
  printf '%s\n' "$*"
}

run_cmd() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

should_skip_source() {
  local rel="$1"
  local item
  for item in "${SKIP_SOURCES[@]}"; do
    if [[ "${item}" == "${rel}" ]]; then
      return 0
    fi
  done
  # macOS Finder state. Already gitignored, but can exist in a working tree.
  if [[ "$(basename -- "${rel}")" == ".DS_Store" ]]; then
    return 0
  fi
  # A package's own top-level documentation, e.g. "zsh/CLAUDE.md". Most packages
  # have one, so they all map to the single target ~/CLAUDE.md and overwrite each
  # other; whichever package came last in MANAGED_PACKAGES won, which also made
  # repeated runs non-idempotent. The genuinely managed global rules file is
  # ai/.claude/CLAUDE.md -> ~/.claude/CLAUDE.md; it has one more path component
  # and is therefore not matched here.
  if [[ "${rel}" == */CLAUDE.md ]] && [[ "${rel}" != */*/CLAUDE.md ]]; then
    return 0
  fi
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home)
      HOME_DIR="$2"
      shift 2
      ;;
    --backup)
      BACKUP_ROOT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${BACKUP_ROOT}" ]]; then
  BACKUP_ROOT="${HOME_DIR}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
fi

linked=0
backed_up=0
skipped=0

run_cmd mkdir -p "${BACKUP_ROOT}"

for pkg in "${MANAGED_PACKAGES[@]}"; do
  pkg_root="${REPO_ROOT}/${pkg}"
  [[ -d "${pkg_root}" ]] || continue

  while IFS= read -r source; do
    rel="${source#${REPO_ROOT}/}"
    if should_skip_source "${rel}"; then
      skipped=$((skipped + 1))
      continue
    fi

    target_rel="${rel#${pkg}/}"
    target="${HOME_DIR}/${target_rel}"
    parent_dir="$(dirname -- "${target}")"
    backup_path="${BACKUP_ROOT}/${target_rel}"

    if [[ -L "${target}" ]] && [[ "$(readlink "${target}")" == "${source}" ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    # An ancestor directory may already be a symlink into this repository, for
    # example ~/.config/yazi/plugins -> <repo>/cli/.config/yazi/plugins. Because
    # this loop walks individual files, ${target} would then resolve back to
    # ${source} itself, and the code below would move the repository's own file
    # into the backup directory and replace it with a symlink pointing at
    # itself, destroying the content. Detect that case and leave it alone: the
    # file is already managed through the ancestor link.
    if [[ -d "${parent_dir}" ]]; then
      resolved_parent="$(cd "${parent_dir}" 2>/dev/null && pwd -P)"
      if [[ -n "${resolved_parent}" ]] &&
        [[ "${resolved_parent}/$(basename -- "${target}")" == "${source}" ]]; then
        skipped=$((skipped + 1))
        continue
      fi
    fi

    run_cmd mkdir -p "${parent_dir}"
    run_cmd mkdir -p "$(dirname -- "${backup_path}")"

    if [[ -e "${target}" || -L "${target}" ]]; then
      run_cmd mv "${target}" "${backup_path}"
      backed_up=$((backed_up + 1))
    fi

    run_cmd ln -s "${source}" "${target}"
    linked=$((linked + 1))
  done < <(find "${pkg_root}" -type f ! -name '*.example' | sort)
done

log
log "repo_root: ${REPO_ROOT}"
log "home_dir: ${HOME_DIR}"
log "backup_root: ${BACKUP_ROOT}"
log "linked: ${linked}"
log "backed_up: ${backed_up}"
log "skipped: ${skipped}"
log
log "Templates not linked automatically:"
for hint in "${TEMPLATE_HINTS[@]}"; do
  log "  - ${hint}"
done
log
log "Next steps on a new machine:"
log "  1. Review template files and materialize the ones you actually want."
log "  2. Install package dependencies separately, e.g. brew file install --file cli/.config/brewfile/Brewfile"
log "  3. Optionally restore VS Code extensions with ./scripts/install-vscode-extensions.sh"
log "  4. Open a new shell and verify linked configs are taking effect."
