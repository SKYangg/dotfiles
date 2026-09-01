# Key bindings. Must load before 20-tools.fish, because changing the binding
# mode resets all bindings, which would wipe the atuin/fzf bindings that file
# installs.

# ~/.zshrc selects vi mode (`bindkey -v`, reasserted after Kaku's integration
# overrides it). Fish previously erased fish_key_bindings entirely, which left
# it on the default emacs mode, so the two shells disagreed on every editing
# keystroke. Match zsh here.
#
# A stale *universal* fish_key_bindings would override this global one, so erase
# it first; universal variables persist in fish_variables outside this repo and
# would otherwise silently win.
set --erase --universal fish_key_bindings 2>/dev/null
set -g fish_key_bindings fish_vi_key_bindings

# Zsh sets KEYTIMEOUT=1 (10ms) so ESC leaves insert mode without a delay. Fish's
# equivalent is fish_escape_delay_ms, whose minimum accepted value is 10.
set -g fish_escape_delay_ms 10
