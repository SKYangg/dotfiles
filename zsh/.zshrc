# Enable Powerlevel10k instant prompt. Keep this near the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Shared environment and aliases
[ -f "$HOME/.zshrc.env" ] && source "$HOME/.zshrc.env"

# Oh My Zsh
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
	rsync
	git
	aliases
	zsh-syntax-highlighting
	cp
	thefuck
	colored-man-pages
	web-search
	extract
	tmux
	uv
	conda
	zsh-autosuggestions
	command-not-found
	docker
	docker-compose
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
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

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



# Added by CodeBuddy
export PATH="/Users/skyang/.codebuddy/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# CCG multi-model collaboration system
export PATH="/Users/skyang/.claude/bin:$PATH"

[[ ":$PATH:" != *":$HOME/.config/kaku/zsh/bin:"* ]] && export PATH="$HOME/.config/kaku/zsh/bin:$PATH" # Kaku PATH Integration
[[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]] && source "$HOME/.config/kaku/zsh/kaku.zsh" # Kaku Shell Integration

# pnpm
export PNPM_HOME="/Users/skyang/Library/pnpm"
case ":$PATH:" in
	*":$PNPM_HOME:"*) ;;
	*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# nanobrew
export PATH="/opt/nanobrew/prefix/bin:$PATH"
# quarkdown
export PUPPETEER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
