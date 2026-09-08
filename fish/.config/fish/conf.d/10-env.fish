# Environment variables. Mirrors ~/.zshrc.env so both shells agree.

set -q DOTFILES_ROOT; or set -gx DOTFILES_ROOT $HOME/dotfiles

# Let Julia pick the thread count from the host instead of hardcoding a number,
# which would be wrong on any machine with a different core count.
set -gx JULIA_NUM_THREADS auto

if test -d "$HOME/Documents/MATLAB"
    set -q MATLAB; or set -gx MATLAB $HOME/Documents/MATLAB
end

# NVM itself is a POSIX shell function and cannot run under fish. Rather than
# leaving fish on whatever node Homebrew installed (a different major version
# than the one nvm selects, which silently changes behaviour between shells),
# resolve nvm's `default` alias and put that version's bin on PATH. This mirrors
# what sourcing nvm.sh does in zsh for a non-interactive default.
#
# Install the `nvm.fish` plugin if switching versions from within fish is needed;
# it takes over from here because a plugin-managed version is prepended later.
set -q NVM_DIR; or set -gx NVM_DIR $HOME/.nvm

if test -d $NVM_DIR/versions/node
    set -l want
    if test -f $NVM_DIR/alias/default
        set want (string trim < $NVM_DIR/alias/default)
    end

    set -l target
    if test -n "$want"
        # The alias may be a full version ("v24.11.1") or a partial line ("24").
        if test -d $NVM_DIR/versions/node/$want
            set target $NVM_DIR/versions/node/$want
        else
            # Highest installed version matching the prefix, so "24" resolves to
            # the newest v24.x rather than an arbitrary one.
            set -l matches $NVM_DIR/versions/node/v$want*
            if test (count $matches) -gt 0 -a -d "$matches[1]"
                set target (printf '%s\n' $matches | sort -V | tail -1)
            end
        end
    end

    if test -n "$target" -a -d "$target/bin"
        fish_add_path --global --path $target/bin
    end
end

# Resolve the active JDK dynamically. A hardcoded path breaks silently on every
# JDK upgrade and leaves JAVA_HOME pointing at a directory that no longer
# exists, which in turn breaks maven/gradle/sbt while `java` keeps working via
# the /usr/bin/java stub.
if not set -q JAVA_HOME; and test "$DOTFILES_PLATFORM" = macos; and test (uname) = Darwin; and test -x /usr/libexec/java_home
    set -l java_home (/usr/libexec/java_home 2>/dev/null)
    # Guard against an empty result: `set -gx JAVA_HOME ""` would make the path
    # below "/bin", which exists and would wrongly jump to the front of PATH.
    if test -n "$java_home"
        set -gx JAVA_HOME $java_home
        fish_add_path --global --path $JAVA_HOME/bin
    end
else if test "$DOTFILES_PLATFORM" = linux; and test (uname) = Linux; and not set -q JAVA_HOME; and type -q java; and type -q readlink
    # Linux distributions normally expose java through /usr/bin/java ->
    # /etc/alternatives/java. Resolve that link instead of assuming a JDK
    # vendor or version.
    set -l java_real (readlink -f (command -s java) 2>/dev/null)
    if string match -q '*/bin/java' -- "$java_real"
        set -l java_home (path dirname (path dirname "$java_real"))
        if test -d "$java_home"
            set -gx JAVA_HOME $java_home
            fish_add_path --global --path $JAVA_HOME/bin
        end
    end
end

if not set -q PNPM_HOME
    if test "$DOTFILES_PLATFORM" = macos
        set -gx PNPM_HOME $HOME/Library/pnpm
    else if set -q XDG_DATA_HOME
        set -gx PNPM_HOME $XDG_DATA_HOME/pnpm
    else
        set -gx PNPM_HOME $HOME/.local/share/pnpm
    end
end
fish_add_path --global --path $PNPM_HOME

if not set -q PUPPETEER_EXECUTABLE_PATH
    if test "$DOTFILES_PLATFORM" = macos; and test -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        set -gx PUPPETEER_EXECUTABLE_PATH "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    else
        for _dotfiles_browser in google-chrome chromium chromium-browser
            if type -q $_dotfiles_browser
                set -gx PUPPETEER_EXECUTABLE_PATH (command -s $_dotfiles_browser)
                break
            end
        end
    end
end

# Keep Codex's Julia packages, artifacts and compiled caches in a persistent
# depot while retaining the normal user depot as a fallback. Mirrors the same
# block in ~/.zprofile.
if set -q CODEX_SHELL; and test "$CODEX_SHELL" = 1; and not set -q JULIA_DEPOT_PATH
    set -gx JULIA_DEPOT_PATH $HOME/.julia-codex:$HOME/.julia:
end

# Named-directory replacement. Zsh has `hash -d iC=...`, which lets `~iC` expand
# to the iCloud Drive path; fish has no equivalent, so expose it as a variable
# and use `$iC` instead.
if test "$DOTFILES_PLATFORM" = macos; and test -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    set -g iC "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
end

# Deliberately not ported: ZSH, ZSH_THEME and ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE.
# Those configure Oh My Zsh and zsh-autosuggestions, which have no fish
# counterpart; fish's built-in autosuggestion colour is set in 40-colors.fish
# via fish_color_autosuggestion.
