# PATH bootstrap. Loaded first (conf.d is sourced in alphabetical order).
#
# Homebrew is NOT in /etc/paths or /etc/paths.d on this machine, so nothing puts
# /opt/homebrew/bin on PATH by default. Zsh gets it from `brew shellenv` in
# ~/.zprofile, but that file is zsh-only and fish never reads it. Without the
# line below, a fish session started directly by a terminal (rather than via
# `exec fish` from an already-configured zsh) has no brew, starship, zoxide,
# atuin, fzf, eza or conda at all.
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
end

# Homebrew mirrors, mirroring ~/.zprofile so both shells fetch from the same
# place instead of one silently falling back to the upstream remote.
set -gx HOMEBREW_BREW_GIT_REMOTE https://mirrors.ustc.edu.cn/brew.git
set -gx HOMEBREW_CORE_GIT_REMOTE https://mirrors.ustc.edu.cn/homebrew-core.git
set -gx HOMEBREW_BOTTLE_DOMAIN https://mirrors.ustc.edu.cn/homebrew-bottles
set -gx HOMEBREW_API_DOMAIN https://mirrors.ustc.edu.cn/homebrew-bottles/api

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
#   /opt/homebrew/opt/fzf/bin  fzf is already on PATH via /opt/homebrew/bin.
#   ~/.config/kaku/zsh/bin     Kaku is zsh-only; the real yazi is in brew.
#   ~/.pi/agent/bin            injected at runtime by the pi agent, not a dotfile.

# Stale entries that can survive in an exported PATH inherited from a parent
# shell even after their configuration was removed. Mirrors `path_remove` in
# ~/.zshenv. Host-injected and third-party manager paths are left untouched.
for dir in /opt/nanobrew/prefix/bin \
    $HOME/claude-model/bin \
    $HOME/.codebuddy/bin \
    /Applications/MATLAB_R2025b.app/bin \
    /Library/Java/JavaVirtualMachines/amazon-corretto-23.jdk/Contents/Home/bin

    if set -l i (contains --index -- $dir $PATH)
        set --erase PATH[$i]
    end
end
