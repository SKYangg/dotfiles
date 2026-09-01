# Enable Powerlevel10k instant prompt. Keep this near the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Shared environment
[ -f "$HOME/.zshrc.env" ] && source "$HOME/.zshrc.env"

# Oh My Zsh
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
	# Core
	git
	aliases

	# File & system utilities
	cp
	rsync
	extract
	colored-man-pages

	# Shell tools
	tmux
	web-search
	command-not-found

	# Dev environments
	uv
	conda
	docker
	docker-compose

	# Must be last
	zsh-autosuggestions
	zsh-syntax-highlighting
)

# Custom completions must join fpath before compinit runs inside oh-my-zsh.sh,
# otherwise they are never loaded (~/.zsh/completions/_opencli was dead).
fpath=("$HOME/.zsh/completions" $fpath)

source "$ZSH/oh-my-zsh.sh"

# Set after oh-my-zsh.sh or OMZ's default (10000) wins. HISTSIZE is 50000, so
# the old mismatch discarded 80% of history on exit.
SAVEHIST=50000
[ -f "$HOME/.zshrc.aliases" ] && source "$HOME/.zshrc.aliases"

# Named directories
hash -d iC=~/Library/Mobile\ Documents/com~apple~CloudDocs

# Conda
# This installation does not auto-activate an environment, so defer its shell
# hook until `conda` or one of the conda aliases is first used.
typeset -g _DOTFILES_CONDA_LOADED=0
_dotfiles_conda_load() {
	(( _DOTFILES_CONDA_LOADED )) && return 0

	local conda_exe="/opt/homebrew/Caskroom/miniconda/base/bin/conda"
	if [[ ! -x "$conda_exe" ]]; then
		print -u2 "Conda executable not found: $conda_exe"
		return 127
	fi

	local conda_hook
	conda_hook="$("$conda_exe" shell.zsh hook 2>/dev/null)" || return 1
	[[ -n "$conda_hook" ]] || return 1
	eval "$conda_hook" || return 1
	_DOTFILES_CONDA_LOADED=1
}
conda() {
	_dotfiles_conda_load || return
	conda "$@"
}

# Shell tools
bindkey -v
eval "$(zoxide init zsh --cmd cd)"
eval "$(atuin init zsh)"

[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# NVM is expensive to source and does not need to be present for every shell.
# Load it on the first nvm/node/npm invocation, including its completion only
# after NVM itself is available.
typeset -g _DOTFILES_NVM_LOADED=0
_dotfiles_nvm_load() {
	(( _DOTFILES_NVM_LOADED )) && return 0
	if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
		print -u2 "NVM not found: $NVM_DIR/nvm.sh"
		return 127
	fi

	. "$NVM_DIR/nvm.sh" || return
	[[ ! -s "$NVM_DIR/bash_completion" ]] || . "$NVM_DIR/bash_completion" || return
	_DOTFILES_NVM_LOADED=1
}
nvm() {
	_dotfiles_nvm_load || return
	nvm "$@"
}
_dotfiles_nvm_lazy_command() {
	local command_name="$1"
	shift
	_dotfiles_nvm_load || return
	command "$command_name" "$@"
}
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
	node() { _dotfiles_nvm_lazy_command node "$@"; }
	npm() { _dotfiles_nvm_lazy_command npm "$@"; }
	npx() { _dotfiles_nvm_lazy_command npx "$@"; }
	corepack() { _dotfiles_nvm_lazy_command corepack "$@"; }
fi

function y() {
	local tmp cwd
	tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Kaku is managed outside this repository. It initializes Starship only when
# TERM_PROGRAM=Kaku, so keep p10k authoritative by hiding only Starship's
# directory while sourcing Kaku; the rest of Kaku's integrations remain active.
if [[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]]; then
	if [[ "${TERM_PROGRAM:-}" == "Kaku" && -n "${commands[starship]:-}" ]]; then
		typeset -a _dotfiles_saved_path
		typeset _dotfiles_starship_path _dotfiles_starship_dir _dotfiles_path_entry
		_dotfiles_starship_path="${commands[starship]}"
		_dotfiles_starship_dir="${_dotfiles_starship_path:h}"
		_dotfiles_saved_path=("${path[@]}")
		path=()
		for _dotfiles_path_entry in "${_dotfiles_saved_path[@]}"; do
			[[ "$_dotfiles_path_entry" != "$_dotfiles_starship_dir" ]] && path+=("$_dotfiles_path_entry")
		done
		rehash
		source "$HOME/.config/kaku/zsh/kaku.zsh"
		path=("${_dotfiles_saved_path[@]}")
		rehash
		unset _dotfiles_saved_path _dotfiles_starship_path _dotfiles_starship_dir _dotfiles_path_entry
	else
		source "$HOME/.config/kaku/zsh/kaku.zsh"
	fi
fi
[[ -d "$HOME/.config/kaku/zsh/bin" ]] && path_prepend "$HOME/.config/kaku/zsh/bin"

# Kaku calls bindkey -e; restore the selected vi mode after its integration.
KEYTIMEOUT=1
bindkey -v
bindkey -M emacs '^R' atuin-search
bindkey -M viins '^R' atuin-search-viins
bindkey -M vicmd '^R' atuin-search-vicmd
