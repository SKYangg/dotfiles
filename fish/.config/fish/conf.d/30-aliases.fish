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
alias ff fastfetch
alias vi vim

function _dotfiles_copy
    if type -q pbcopy
        command pbcopy
    else if type -q wl-copy
        command wl-copy
    else if type -q xclip
        command xclip -selection clipboard
    else
        echo "No clipboard command found (pbcopy, wl-copy, or xclip)" >&2
        return 127
    end
end
function pwc
    pwd | _dotfiles_copy
end

if type -q brew
    alias br brew
    function brup
        brew update; and brew upgrade; and brew cleanup
    end
end
if type -q matlab
    alias m-cli "matlab -nodesktop"
end

# Config editing
alias fishconfig "vi ~/.config/fish/config.fish"
alias zshconfig "vi ~/.zshrc"
alias vimconfig "vi ~/.vimrc"
alias sshconfig "vi ~/.ssh/config"

# Maintenance
if type -q networksetup
    alias prxon "sudo networksetup -setsocksfirewallproxystate Wi-Fi on"
    alias prxof "sudo networksetup -setsocksfirewallproxystate Wi-Fi off"
end

# Project-specific helpers. The venv activation script has a fish-specific
# variant; sourcing the POSIX one would fail.
if test -f "$HOME/Tools/pdf_grabber/.venv/bin/activate.fish"; and test -f "$HOME/Tools/pdf_grabber/download_pdfs.py"
    function dld
        source "$HOME/Tools/pdf_grabber/.venv/bin/activate.fish"; and \
            python "$HOME/Tools/pdf_grabber/download_pdfs.py" $argv
    end
end
