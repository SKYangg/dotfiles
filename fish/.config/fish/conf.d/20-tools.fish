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

# fzf's own --fish output supersedes the key-bindings.fish file shipped in
# /opt/homebrew/opt/fzf/shell.
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

# Conda ships a real fish hook, so unlike nvm it works natively. Sourcing the
# hook only defines the `conda` function and does not activate an environment,
# which is why no base environment is auto-activated here.
if test -f /opt/homebrew/Caskroom/miniconda/base/etc/fish/conf.d/conda.fish
    source /opt/homebrew/Caskroom/miniconda/base/etc/fish/conf.d/conda.fish
end

# Deliberately not ported: Kaku's shell integration and Powerlevel10k. Kaku
# ships zsh only (~/.config/kaku/zsh), and the prompt in fish is starship, set
# up in config.fish. That also makes the PATH juggling ~/.zshrc needs to hide
# starship from Kaku unnecessary here.
