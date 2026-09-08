# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
	for _dotfiles_brew_prefix in \
		/opt/homebrew \
		/usr/local \
		/home/linuxbrew/.linuxbrew \
		"$HOME/.linuxbrew"; do
		if [[ -x "${_dotfiles_brew_prefix}/bin/brew" ]]; then
			HOMEBREW_PREFIX="${_dotfiles_brew_prefix}"
			break
		fi
	done
fi

if [[ -n "${HOMEBREW_PREFIX:-}" && -x "${HOMEBREW_PREFIX}/bin/brew" ]]; then
	eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv zsh)"

	# Keep the mirror policy opt-in for hosts that use Homebrew. A Linux host
	# without brew should not receive unrelated Homebrew environment variables.
	export HOMEBREW_BREW_GIT_REMOTE="${HOMEBREW_BREW_GIT_REMOTE:-https://mirrors.ustc.edu.cn/brew.git}"
	export HOMEBREW_CORE_GIT_REMOTE="${HOMEBREW_CORE_GIT_REMOTE:-https://mirrors.ustc.edu.cn/homebrew-core.git}"
	export HOMEBREW_BOTTLE_DOMAIN="${HOMEBREW_BOTTLE_DOMAIN:-https://mirrors.ustc.edu.cn/homebrew-bottles}"
	export HOMEBREW_API_DOMAIN="${HOMEBREW_API_DOMAIN:-https://mirrors.ustc.edu.cn/homebrew-bottles/api}"
fi

unset _dotfiles_brew_prefix

# Keep Codex's Julia packages, artifacts, and compiled caches in a persistent
# depot while retaining the normal user depot as a fallback.
if [[ "${CODEX_SHELL:-}" == "1" && -z "${JULIA_DEPOT_PATH:-}" ]]; then
	export JULIA_DEPOT_PATH="$HOME/.julia-codex:$HOME/.julia:"
fi
