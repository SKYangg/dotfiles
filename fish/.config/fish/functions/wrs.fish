# Force-restart WindowServer. Ported from ~/.zshrc.aliases.
#
# This tears down the whole GUI session and loses all unsaved work, so it must
# never be one keystroke away. Kept as a function rather than an alias so the
# confirmation prompt is possible.
function wrs --description 'Force-restart WindowServer (logs you out immediately)'
    if test (uname) != Darwin
        echo "wrs is only available on macOS (WindowServer is not present here)." >&2
        return 1
    end
    echo "WARNING: this force-kills WindowServer, logging you out immediately." >&2
    echo "All unsaved work in every application will be lost." >&2
    read -l -P "Type 'yes' to continue: " reply
    if test "$reply" != yes
        echo "Aborted." >&2
        return 1
    end
    pgrep WindowServer | xargs sudo kill -9
end
