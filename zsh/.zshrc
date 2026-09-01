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
# Contents in this block are managed by `conda init`.
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
	eval "$__conda_setup"
else
	if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
		. "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
	else
		export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
	fi
fi
unset __conda_setup

# Shell tools
bindkey -v
eval "$(zoxide init zsh --cmd cd)"
eval "$(atuin init zsh)"

[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

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
