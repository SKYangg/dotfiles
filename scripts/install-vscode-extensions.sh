#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${REPO_ROOT}/editor/.vscode/extensions/extensions.list"
CODE_BIN="code"
DRY_RUN=0
FORCE=0

usage() {
  cat <<'EOF'
Usage: ./scripts/install-vscode-extensions.sh [options]

Install VS Code-compatible extensions from the portable manifest in this repo.

Options:
  --manifest FILE   Read extension IDs from FILE
  --code-bin BIN    Use BIN instead of `code`
  --force           Reinstall extensions even if already present
  --dry-run         Print commands without executing them
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest)
      MANIFEST="$2"
      shift 2
      ;;
    --code-bin)
      CODE_BIN="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
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

if [[ ! -f "${MANIFEST}" ]]; then
  printf 'Manifest not found: %s\n' "${MANIFEST}" >&2
  exit 1
fi

if [[ "${DRY_RUN}" -eq 0 ]] && ! command -v "${CODE_BIN}" >/dev/null 2>&1; then
  printf 'Command not found: %s\n' "${CODE_BIN}" >&2
  printf 'Install the editor CLI or rerun with --code-bin.\n' >&2
  exit 1
fi

installed=0

while IFS= read -r extension_id || [[ -n "${extension_id}" ]]; do
  [[ -z "${extension_id}" ]] && continue
  [[ "${extension_id}" == \#* ]] && continue

  cmd=("${CODE_BIN}" "--install-extension" "${extension_id}")
  if [[ "${FORCE}" -eq 1 ]]; then
    cmd+=("--force")
  fi

  run_cmd "${cmd[@]}"
  installed=$((installed + 1))
done < "${MANIFEST}"

log
log "manifest: ${MANIFEST}"
log "code_bin: ${CODE_BIN}"
log "requested_installs: ${installed}"
