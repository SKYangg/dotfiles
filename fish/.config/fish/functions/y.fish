# yazi wrapper that changes the shell's directory to wherever yazi was left.
# Ported from the `y` function in ~/.zshrc.
function y --description 'Open yazi and cd to its last directory'
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file="$tmp"
    if set -l cwd (command cat -- "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
