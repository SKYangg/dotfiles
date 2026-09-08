# PATH bootstrap. Loaded first (conf.d is sourced in alphabetical order).
#
if not set -q DOTFILES_PLATFORM
    switch (uname)
        case Darwin
            set -gx DOTFILES_PLATFORM macos
        case Linux
            set -gx DOTFILES_PLATFORM linux
        case '*'
            set -gx DOTFILES_PLATFORM unknown
    end
end

# Fish does not read ~/.zprofile, so discover Homebrew independently when it is
# installed. The candidates cover the standard macOS and Linux prefixes while
# still allowing a custom HOMEBREW_PREFIX.
set -l _dotfiles_brew_bin
if type -q brew
    set _dotfiles_brew_bin (command -s brew)
else
    set -l _dotfiles_brew_prefixes
    if set -q HOMEBREW_PREFIX
        set --append _dotfiles_brew_prefixes $HOMEBREW_PREFIX
    end
    set --append _dotfiles_brew_prefixes \
        /opt/homebrew \
        /usr/local \
        /home/linuxbrew/.linuxbrew \
        $HOME/.linuxbrew
    for _dotfiles_brew_prefix in $_dotfiles_brew_prefixes
        if test -x "$_dotfiles_brew_prefix/bin/brew"
            set _dotfiles_brew_bin "$_dotfiles_brew_prefix/bin/brew"
            break
        end
    end
end

if test -n "$_dotfiles_brew_bin"
    "$_dotfiles_brew_bin" shellenv fish | source

    # Keep the mirror policy scoped to hosts that actually use Homebrew.
    set -q HOMEBREW_BREW_GIT_REMOTE; or set -gx HOMEBREW_BREW_GIT_REMOTE https://mirrors.ustc.edu.cn/brew.git
    set -q HOMEBREW_CORE_GIT_REMOTE; or set -gx HOMEBREW_CORE_GIT_REMOTE https://mirrors.ustc.edu.cn/homebrew-core.git
    set -q HOMEBREW_BOTTLE_DOMAIN; or set -gx HOMEBREW_BOTTLE_DOMAIN https://mirrors.ustc.edu.cn/homebrew-bottles
    set -q HOMEBREW_API_DOMAIN; or set -gx HOMEBREW_API_DOMAIN https://mirrors.ustc.edu.cn/homebrew-bottles/api
end

# ~/.cargo/env and ~/.goup/env are POSIX scripts, so fish cannot source them.
# Add their bin directories directly instead.
#
# `fish_add_path --global --path` is the fish equivalent of the `path_prepend`
# helper in ~/.zshenv: it prepends, silently skips directories that do not
# exist, and is idempotent, so no dead or duplicate entries accumulate across
# nested shells. This replaces zsh's `typeset -U path`.
#
# Arguments are applied in order, first argument ending up highest priority.
fish_add_path --global --path \
    $HOME/src/scripts \
    $HOME/.local/bin \
    $HOME/.claude/bin \
    $HOME/.cargo/bin \
    $HOME/.goup/bin \
    $HOME/.goup/current/bin

# OrbStack ships a fish init, unlike Kaku and nvm. Mirrors the init.zsh line in
# ~/.zprofile; without it `docker`, `orb` and friends are missing from fish.
if test -f $HOME/.orbstack/shell/init2.fish
    source $HOME/.orbstack/shell/init2.fish 2>/dev/null; or true
end

# Deliberately not added, to document that the difference from zsh is intended:
#   the package-specific fzf directory is unnecessary when its main bin
#   directory is already on PATH.
#   ~/.config/kaku/zsh/bin     Kaku is zsh-only; the real yazi is in brew.
#   ~/.pi/agent/bin            injected at runtime by the pi agent, not a dotfile.

# Stale entries that can survive in an exported PATH inherited from a parent
# shell even after their configuration was removed. Mirrors `path_remove` in
# ~/.zshenv. Host-injected and third-party manager paths are left untouched.
if test "$DOTFILES_PLATFORM" = macos
    for dir in $HOME/claude-model/bin \
        $HOME/.codebuddy/bin

        if set -l i (contains --index -- $dir $PATH)
            set --erase PATH[$i]
        end
    end
end
