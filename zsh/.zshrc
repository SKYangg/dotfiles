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
	thefuck
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

source "$ZSH/oh-my-zsh.sh"
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
eval "$(zoxide init zsh --cmd cd)"
eval "$(atuin init zsh)"
bindkey -v

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
HISTFILE=~/.zsh_history

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
