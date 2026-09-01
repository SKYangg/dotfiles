# Fish entry point.
#
# Configuration is split into ~/.config/fish/conf.d/, which fish sources in
# alphabetical order before this file:
#
#   00-path.fish         brew shellenv, PATH construction and pruning
#   10-env.fish          exported environment variables
#   15-keybindings.fish  vi mode (before 20-tools so tool bindings survive)
#   20-tools.fish        zoxide, atuin, fzf, conda
#   30-aliases.fish      aliases
#   40-colors.fish       syntax highlighting and pager colours
#
# Autoloaded functions live in ~/.config/fish/functions/ (`y`, `wrs`).

if status is-interactive
    # Prompt. `| source` replaces the older `| .`; the `.` builtin is a
    # deprecated alias for `source` and emits a warning on modern fish.
    if command -q starship
        starship init fish | source
    end
end
