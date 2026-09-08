# Deduplicate PATH/FPATH. Because PATH is exported and re-prepended by every
# nested shell, without this the entry count grows without bound (was +9 per
# nesting level). `typeset -U` also collapses duplicates inherited from a parent.
typeset -U path PATH fpath FPATH

# Keep the repository and platform discoverable without baking this machine's
# absolute path into every tool-specific file. The value can be overridden by
# a host profile when the repository is cloned somewhere else.
if [[ -z "${DOTFILES_PLATFORM:-}" ]]; then
	case "${OSTYPE:-}" in
		darwin*) DOTFILES_PLATFORM=macos ;;
		linux*) DOTFILES_PLATFORM=linux ;;
		*) DOTFILES_PLATFORM=unknown ;;
	esac
fi
export DOTFILES_PLATFORM
export DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"

# Prepend a directory to PATH only if it exists, so missing tools never leave
# dead entries behind. Defined here (earliest-loaded file) so .zshrc.env and
# .zshrc can both use it.
path_prepend() {
	local dir
	for dir in "$@"; do
		[[ -d "$dir" ]] && path=("$dir" $path)
	done
}

# Remove only stale entries owned by the dotfiles configuration. Host-injected
# entries and third-party manager paths are intentionally left untouched.
path_remove() {
	local dir
	for dir in "$@"; do
		path=("${(@)path:#$dir}")
	done
}

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f "$HOME/.goup/env" ] && . "$HOME/.goup/env"

# These entries can survive in PATH inherited from an already-running parent
# shell even after their configuration lines have been removed.
path_remove \
	"$HOME/claude-model/bin" \
	"$HOME/.codebuddy/bin"

# uv
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.claude/bin"
