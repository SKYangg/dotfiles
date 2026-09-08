[ -n "${DOTFILES_ROOT:-}" ] || export DOTFILES_ROOT="$HOME/dotfiles"
if [ -z "${DOTFILES_PLATFORM:-}" ]; then
    case "$(uname -s)" in
        Darwin) DOTFILES_PLATFORM=macos ;;
        Linux) DOTFILES_PLATFORM=linux ;;
        *) DOTFILES_PLATFORM=unknown ;;
    esac
    export DOTFILES_PLATFORM
fi
[ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X" # boot up x-cmd.

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
[ ! -f "$HOME/.cargo/env" ] || . "$HOME/.cargo/env"
