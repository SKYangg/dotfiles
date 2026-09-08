# Tool integrations. Mirrors the `eval "$(... init zsh)"` block in ~/.zshrc.
# Interactive-only: these install key bindings and prompts, which are useless
# and slow in scripts.
status is-interactive; or exit 0

# zoxide replaces cd, so plain `cd` gains frecency jumping and `cdi` opens the
# interactive picker. Note this makes `z`/`zi` nonexistent, matching the comment
# in ~/.zshrc.aliases.
if command -q zoxide
    zoxide init fish --cmd cd | source
end

# fzf's own --fish output supersedes the key-bindings.fish file shipped by the
# installed package.
#
# Loaded BEFORE atuin on purpose: fzf also binds Ctrl-R to its own history
# widget, and whichever integration loads last wins. ~/.zshrc binds Ctrl-R to
# atuin explicitly, so atuin must come second here to match. fzf's other
# bindings (Ctrl-T for files, Alt-C for directories) are unaffected.
if command -q fzf
    fzf --fish | source
end

# atuin owns shell history. --disable-up-arrow keeps fish's native prefix search
# on the up arrow (the main reason to use fish interactively) and leaves history
# search on Ctrl-R, matching the explicit atuin-search bindings in ~/.zshrc.
if command -q atuin
    atuin init fish --disable-up-arrow | source
end

# Conda ships a real fish hook, so unlike nvm it works natively. Find the hook
# from the active installation instead of assuming Homebrew's macOS prefix.
set -l _dotfiles_conda_hooks
if set -q CONDA_EXE
    set --append _dotfiles_conda_hooks (path dirname (path dirname "$CONDA_EXE"))/etc/fish/conf.d/conda.fish
end
set --append _dotfiles_conda_hooks \
    $HOME/miniconda3/etc/fish/conf.d/conda.fish \
    $HOME/anaconda3/etc/fish/conf.d/conda.fish \
    $HOME/.local/conda/etc/fish/conf.d/conda.fish \
    /opt/conda/etc/fish/conf.d/conda.fish
if type -q brew
    set -l _dotfiles_brew_conda_prefix (brew --prefix miniconda 2>/dev/null)
    if test -n "$_dotfiles_brew_conda_prefix"
        set --append _dotfiles_conda_hooks "$_dotfiles_brew_conda_prefix/etc/fish/conf.d/conda.fish"
    end
end
if set -q HOMEBREW_PREFIX
    set --append _dotfiles_conda_hooks "$HOMEBREW_PREFIX/Caskroom/miniconda/base/etc/fish/conf.d/conda.fish"
end
for _dotfiles_conda_hook in $_dotfiles_conda_hooks
    if test -f "$_dotfiles_conda_hook"
        source "$_dotfiles_conda_hook"
        break
    end
end

# Deliberately not ported: Kaku's shell integration and Powerlevel10k. Kaku
# ships zsh only (~/.config/kaku/zsh), and the prompt in fish is starship, set
# up in config.fish. That also makes the PATH juggling ~/.zshrc needs to hide
# starship from Kaku unnecessary here.
