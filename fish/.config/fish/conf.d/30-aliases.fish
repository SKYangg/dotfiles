# Aliases. Mirrors ~/.zshrc.aliases.
#
# In fish an alias is a thin wrapper around `function`, so these are only
# defined for the current session. That is intentional: keeping them here rather
# than in ~/.config/fish/functions means this repository stays the single source
# of truth, instead of `funcsave` writing copies outside version control.

# Core
alias ls "eza --icons --time-style '+%Y-%m-%d %H:%M:%S'"
alias lg lazygit
alias tree "eza -T"
alias pwc "pwd | pbcopy"
alias ff fastfetch
alias vi vim
alias br brew
alias m-cli "matlab -nodesktop"

# Config editing
alias fishconfig "vi ~/.config/fish/config.fish"
alias zshconfig "vi ~/.zshrc"
alias vimconfig "vi ~/.vimrc"
alias sshconfig "vi ~/.ssh/config"

# Maintenance
alias brup "brew update && brew upgrade && brew cleanup"
alias prxon "sudo networksetup -setsocksfirewallproxystate Wi-Fi on"
alias prxof "sudo networksetup -setsocksfirewallproxystate Wi-Fi off"

# Project-specific helpers. The venv activation script has a fish-specific
# variant; sourcing the POSIX one would fail.
alias dld "source $HOME/Tools/pdf_grabber/.venv/bin/activate.fish && python $HOME/Tools/pdf_grabber/download_pdfs.py"
