export DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"
if [ -z "${DOTFILES_PLATFORM:-}" ]; then
    case "$(uname -s)" in
        Darwin) DOTFILES_PLATFORM=macos ;;
        Linux) DOTFILES_PLATFORM=linux ;;
        *) DOTFILES_PLATFORM=unknown ;;
    esac
fi
export DOTFILES_PLATFORM

# Make Homebrew discoverable without assuming one architecture-specific prefix.
if [ -z "${HOMEBREW_PREFIX:-}" ]; then
    for __dotfiles_brew_prefix in \
        /opt/homebrew \
        /usr/local \
        /home/linuxbrew/.linuxbrew \
        "$HOME/.linuxbrew"; do
        if [ -x "${__dotfiles_brew_prefix}/bin/brew" ]; then
            HOMEBREW_PREFIX="${__dotfiles_brew_prefix}"
            break
        fi
    done
fi
if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -x "${HOMEBREW_PREFIX}/bin/brew" ]; then
    eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv bash)"
fi

# Initialise Conda only when an installation is present. Resolve the executable
# from the environment or common install roots instead of pinning Homebrew's
# macOS prefix and package layout.
__dotfiles_conda_exe=""
if [ -n "${CONDA_EXE:-}" ] && [ -x "${CONDA_EXE}" ]; then
    __dotfiles_conda_exe="${CONDA_EXE}"
elif __dotfiles_conda_exe="$(command -v conda 2>/dev/null)" && [ -x "${__dotfiles_conda_exe}" ]; then
    :
else
    __dotfiles_conda_exe=""
    for __dotfiles_candidate in \
        "$HOME/miniconda3/bin/conda" \
        "$HOME/anaconda3/bin/conda" \
        "$HOME/.local/conda/bin/conda" \
        /opt/conda/bin/conda; do
        if [ -x "${__dotfiles_candidate}" ]; then
            __dotfiles_conda_exe="${__dotfiles_candidate}"
            break
        fi
    done
    if [ -z "${__dotfiles_conda_exe}" ] && command -v brew >/dev/null 2>&1; then
        __dotfiles_brew_conda_prefix="$(brew --prefix miniconda 2>/dev/null || true)"
        if [ -x "${__dotfiles_brew_conda_prefix}/bin/conda" ]; then
            __dotfiles_conda_exe="${__dotfiles_brew_conda_prefix}/bin/conda"
        fi
    fi
    if [ -z "${__dotfiles_conda_exe}" ] && [ -n "${HOMEBREW_PREFIX:-}" ] && [ -x "${HOMEBREW_PREFIX}/Caskroom/miniconda/base/bin/conda" ]; then
        __dotfiles_conda_exe="${HOMEBREW_PREFIX}/Caskroom/miniconda/base/bin/conda"
    fi
fi

if [ -n "${__dotfiles_conda_exe}" ]; then
    __conda_setup="$("${__dotfiles_conda_exe}" shell.bash hook 2>/dev/null)"
    if [ $? -eq 0 ]; then
        eval "${__conda_setup}"
    else
        __dotfiles_conda_prefix="${__dotfiles_conda_exe%/bin/conda}"
        if [ -f "${__dotfiles_conda_prefix}/etc/profile.d/conda.sh" ]; then
            . "${__dotfiles_conda_prefix}/etc/profile.d/conda.sh"
        else
            PATH="${__dotfiles_conda_prefix}/bin:${PATH}"
            export PATH
        fi
    fi
fi
unset __conda_setup __dotfiles_candidate __dotfiles_conda_exe __dotfiles_conda_prefix __dotfiles_brew_conda_prefix __dotfiles_brew_prefix


[ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X" # boot up x-cmd.
[ ! -f "$HOME/.cargo/env" ] || . "$HOME/.cargo/env"
