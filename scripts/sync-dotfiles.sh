#!/usr/bin/env bash
# Deploy the local shell & tool config (Oh My Zsh + Powerlevel10k theme, and
# Yazi file-manager config) to one or more remote hosts (SSH aliases from
# ~/.ssh/config, or user@host).
#
# Purpose: give a newly-provisioned cluster / VPS / server the same zsh theme
# and yazi setup as this machine WITHOUT depending on the remote cloning
# oh-my-zsh / powerlevel10k / yazi plugins from GitHub (the remote's
# ~/.gitconfig may rewrite https to ssh, keys may be absent, or the host may be
# offline). It ships the already-installed local trees/config over rsync.
#
# Shipped groups:
#   zsh   - $HOME/.oh-my-zsh tree                      -> ~/.oh-my-zsh/
#           dotfiles/zsh/{.zshrc,.zshenv,.zprofile,
#                        .zshrc.env,.zshrc.aliases,.p10k.zsh} -> ~/
#   yazi  - dotfiles/cli/.config/yazi/                  -> ~/.config/yazi/
#
# Notes:
#   - idempotent: safe to re-run; existing remote files are backed up before any
#     overwrite, and re-runs skip already-made backups.
#   - host-specific export PATH= lines found in the remote's OLD ~/.zshrc (e.g.
#     a locally installed node toolchain) are preserved by appending them to the
#     new .zshrc, so the sync never silently drops per-host tooling (opt out
#     with -N).
#   - omz tree is rsynced WITHOUT --delete by default (cleans nothing on the
#     remote); pass --replace to mirror remote trees to the local ones.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

HOSTS=()
ZSH_SOURCE="${ZSH_SOURCE:-$REPO_ROOT/zsh}"
OMZ_SOURCE="${OMZ_SOURCE:-$HOME/.oh-my-zsh}"
YAZI_SOURCE="${YAZI_SOURCE:-$REPO_ROOT/cli/.config/yazi}"
DELETE=0
PRESERVE_PATHS=1
BACKUP_SUFFIX=".bak.sync-dotfiles"
DRY_RUN=0
QUIET=0
VERBOSE=0
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15)

# zsh config files shipped from the repo to the remote $HOME.
ZSH_FILES=".zshrc .zshenv .zprofile .zshrc.env .zshrc.aliases .p10k.zsh"

usage() {
  cat <<'EOF'
Usage: ./scripts/sync-dotfiles.sh [options] [HOST...]

Deploy the local zsh theme (Oh My Zsh + Powerlevel10k) and Yazi config to one or
more remote hosts. HOST may be an SSH alias from ~/.ssh/config (e.g. host-a) or
user@host.

Shipped groups:
  zsh   ~/.oh-my-zsh/ -> ~/.oh-my-zsh/  (theme framework, excl .git/.cache)
        dotfiles/zsh/* zsh config files -> ~/
  yazi  dotfiles/cli/.config/yazi/     -> ~/.config/yazi/

Options:
  -H, --host HOST          Target host (repeatable; alternative to positional args)
  -S, --source DIR         Local zsh config source dir (default: <repo>/zsh)
  -Y, --yazi-source DIR    Local yazi config source dir
                           (default: <repo>/cli/.config/yazi)
  -D, --no-delete          Keep remote files not present locally (default; safe)
  -P, --replace            rsync --delete: mirror remote trees to local
  -Y-only | --zsh-only     Limit which groups are deployed
  -N, --no-preserve-paths  Do NOT preserve host-specific export PATH= lines from
                           the remote's old ~/.zshrc (kept by default)
  -B, --backup-suffix S    Backup suffix for existing remote files
                           (default: .bak.sync-dotfiles)
  -n, --dry-run            Print actions without executing
  -q, --quiet              Less output
  -v, --verbose            rsync -v
  -h, --help               Show this help

Examples:
  ./scripts/sync-dotfiles.sh host-a
  ./scripts/sync-dotfiles.sh --host host-a --host user@host
  ./scripts/sync-dotfiles.sh -n --zsh-only host-a   # preview zsh only
EOF
}

say() { [[ "${QUIET}" -eq 0 ]] && printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

DO_ZSH=1
DO_YAZI=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    -H|--host) HOSTS+=("$2"); shift 2 ;;
    -S|--source) ZSH_SOURCE="$2"; shift 2 ;;
    -Y|--yazi-source) YAZI_SOURCE="$2"; shift 2 ;;
    -D|--no-delete) DELETE=0; shift ;;
    -P|--replace) DELETE=1; shift ;;
    -N|--no-preserve-paths) PRESERVE_PATHS=0; shift ;;
    -B|--backup-suffix) BACKUP_SUFFIX="$2"; shift 2 ;;
    --zsh-only) DO_ZSH=1; DO_YAZI=0; shift ;;
    --yazi-only) DO_ZSH=0; DO_YAZI=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -q|--quiet) QUIET=1; shift ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*)
      printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 1 ;;
    *)
      HOSTS+=("$1"); shift ;;
  esac
done

if [[ ${#HOSTS[@]} -eq 0 ]]; then die "no target host given (see --help)"; fi
command -v rsync >/dev/null 2>&1 || die "rsync is required (not found on this machine)"
case "${BACKUP_SUFFIX}" in *[!A-Za-z0-9._-]*)
  die "backup suffix must be alphanumeric/_/./- (got: ${BACKUP_SUFFIX})" ;;
esac
if [[ "${DO_ZSH}" -eq 1 ]]; then
  [[ -d "${ZSH_SOURCE}" ]] || die "zsh source dir not found: ${ZSH_SOURCE} (use -S)"
  [[ -d "${OMZ_SOURCE}" ]] || die "local oh-my-zsh not found: ${OMZ_SOURCE}"
fi
if [[ "${DO_YAZI}" -eq 1 ]]; then
  [[ -d "${YAZI_SOURCE}" ]] || die "yazi source dir not found: ${YAZI_SOURCE} (use -Y)"
fi

# ---------------------------------------------------------------------------
# Remote helper scripts. Written to local temp files and scp'd to avoid fragile
# shell-quoting when building remote commands (matters on macOS bash 3.2).
# ---------------------------------------------------------------------------
TMPDIR_LOCAL="$(mktemp -d "${TMPDIR:-/tmp}/sync-dotfiles.XXXXXX")"
trap 'rm -rf "${TMPDIR_LOCAL}"' EXIT

# Generic backup: copy each $HOME-relative path to $path$bak once (suffix-guarded).
cat > "${TMPDIR_LOCAL}/ssh_backup.sh" <<'REMOTE'
#!/usr/bin/env bash
set -euo pipefail
bak="$1"; shift
for p in "$@"; do
  if [[ -e "$HOME/$p" && ! -e "$HOME/$p$bak" ]]; then
    cp -a "$HOME/$p" "$HOME/$p$bak"
  fi
done
REMOTE

# Append host-specific export PATH= lines from the old .zshrc to the new one,
# skipping lines whose value is already present anywhere in it.
cat > "${TMPDIR_LOCAL}/ssh_preserve_paths.sh" <<'REMOTE'
#!/usr/bin/env bash
set -euo pipefail
bak="$1"
old="$HOME/.zshrc$bak"
new="$HOME/.zshrc"
[[ -f "$old" ]] || exit 0
matches=0
while IFS= read -r line; do
  val="$(printf '%s' "$line" | sed -E 's/.*PATH(\+\+=|=)\s*//')"
  [[ -z "$val" || "$val" == *'$PATH"' ]] && continue
  grep -qF -- "$val" "$new" 2>/dev/null && continue
  printf '\n# Preserved by sync-dotfiles.sh (was in old ~/.zshrc)\n%s\n' "$line" >> "$new"
  matches=$((matches + 1))
done < <(grep -E '^[[:space:]]*export[[:space:]]+PATH(\+\+=|=)' "$old" || true)
printf 'preserved_path_lines=%d\n' "$matches"
REMOTE

send_and_run() {   # send_and_run HOST SCRIPT [ARGS...]
  local host="$1" script="$2"; shift 2
  local name; name="$(basename "${script}")"
  scp -q -o BatchMode=yes "${script}" "${host}:/tmp/${name}"
  ssh -o BatchMode=yes "${host}" "bash /tmp/${name} $*; rm -f /tmp/${name}"
}

# ---------------------------------------------------------------------------
# Per-host migration
# ---------------------------------------------------------------------------
for host in "${HOSTS[@]}"; do
  say "== host: ${host} =="

  if ! ssh "${SSH_OPTS[@]}" "${host}" 'true' 2>/dev/null; then
    warn "${host}: unreachable (BatchMode=yes), skipping — check ~/.ssh/config / key"
    continue
  fi
  if [[ "$(ssh "${SSH_OPTS[@]}" "${host}" 'command -v rsync || echo MISSING')" == "MISSING" ]]; then
    warn "${host}: rsync missing on remote, skipping"
    continue
  fi

  if [[ "${DO_YAZI}" -eq 1 ]]; then
    say "  [yazi] backup + sync ${YAZI_SOURCE}/ -> ${host}:~/.config/yazi/"
    if [[ "${DRY_RUN}" -eq 1 ]]; then
      say "    (dry-run) backup ~/.config/yazi -> *${BACKUP_SUFFIX}"
    else
      send_and_run "${host}" "${TMPDIR_LOCAL}/ssh_backup.sh" "${BACKUP_SUFFIX}" ".config/yazi"
    fi
    rsync -a ${VERBOSE:+-v} ${DELETE:+--delete} \
      --exclude '**/.git' --exclude '*.zwc' \
      ${DRY_RUN:+-n} \
      "${YAZI_SOURCE}/" "${host}:~/.config/yazi/"
  fi

  if [[ "${DO_ZSH}" -eq 1 ]]; then
    if [[ "${DRY_RUN}" -eq 1 ]]; then
      say "  [zsh] (dry-run) backup existing remote zsh config -> *${BACKUP_SUFFIX}"
    else
      send_and_run "${host}" "${TMPDIR_LOCAL}/ssh_backup.sh" "${BACKUP_SUFFIX}" ${ZSH_FILES}
      say "  [zsh] backup: existing remote zsh config -> *${BACKUP_SUFFIX}"
    fi

    say "  [zsh] sync ${OMZ_SOURCE}/ -> ${host}:~/.oh-my-zsh/ (excl .git/.cache/*.zwc)"
    # shellcheck disable=SC2086
    rsync -a ${VERBOSE:+-v} ${DELETE:+--delete} \
      --exclude '**/.git' --exclude '.cache' --exclude '*.zwc' \
      ${DRY_RUN:+-n} \
      "${OMZ_SOURCE}/" "${host}:~/.oh-my-zsh/"

    for f in ${ZSH_FILES}; do
      if [[ -f "${ZSH_SOURCE}/${f}" ]]; then
        say "  [zsh] sync ${f}"
        [[ "${DRY_RUN}" -eq 1 ]] || rsync -a "${ZSH_SOURCE}/${f}" "${host}:~/"
      else
        warn "${host}: ${ZSH_SOURCE}/${f} missing locally, skipped"
      fi
    done

    if [[ "${PRESERVE_PATHS}" -eq 1 ]]; then
      if [[ "${DRY_RUN}" -eq 1 ]]; then
        say "  [zsh] (dry-run) preserve host-specific export PATH= lines from old .zshrc"
      else
        out="$(send_and_run "${host}" "${TMPDIR_LOCAL}/ssh_preserve_paths.sh" "${BACKUP_SUFFIX}")"
        say "  [zsh] preserve: ${out}"
      fi
    fi
  fi

  say "done: ${host}"
done

say
say "Reconnect to the host for the Powerlevel10k prompt / updated yazi theme."