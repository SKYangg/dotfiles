# Deduplicate PATH/FPATH. Because PATH is exported and re-prepended by every
# nested shell, without this the entry count grows without bound (was +9 per
# nesting level). `typeset -U` also collapses duplicates inherited from a parent.
typeset -U path PATH fpath FPATH

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
	/opt/nanobrew/prefix/bin \
	"$HOME/claude-model/bin" \
	"$HOME/.codebuddy/bin" \
	/Applications/MATLAB_R2025b.app/bin \
	/Library/Java/JavaVirtualMachines/amazon-corretto-23.jdk/Contents/Home/bin

# uv
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.claude/bin"
