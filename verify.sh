#!/usr/bin/env bash

set -euo pipefail

required_commands=(fish yazi nvim tree-sitter basedpyright-langserver rg)

for command_name in "${required_commands[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'MISSING_COMMAND=%s\n' "$command_name" >&2
        exit 1
    fi
done

fish -n "$HOME/.config/fish/conf.d/10-editor.fish"

fish_editor="$(fish -lc 'printf "%s" "$EDITOR"')"
fish_visual="$(fish -lc 'printf "%s" "$VISUAL"')"

if [[ "$fish_editor" != "nvim" || "$fish_visual" != "nvim" ]]; then
    printf 'FISH_EDITOR_MISMATCH EDITOR=%s VISUAL=%s\n' "$fish_editor" "$fish_visual" >&2
    exit 1
fi

yazi_debug="$(fish -lc 'yazi --debug 2>/dev/null')"

if ! rg -F 'EDITOR             : Some("nvim")' <<<"$yazi_debug" >/dev/null; then
    printf 'YAZI_EDITOR_NOT_EXPORTED\n' >&2
    exit 1
fi

if ! rg -F 'run: NonEmptyString("nvim %s")' <<<"$yazi_debug" >/dev/null; then
    printf 'YAZI_NVIM_OPENER_MISSING\n' >&2
    exit 1
fi

nvim --headless \
    "+edit /tmp/terminal_toolchain_probe.py" \
    "+set filetype=python" \
    "+lua local ok, parser = pcall(vim.treesitter.get_parser, 0, 'python'); assert(ok, parser); parser:parse(); assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], 'Treesitter highlighter inactive')" \
    +qa!

ghostty_bin="/Applications/Ghostty.app/Contents/MacOS/ghostty"
if [[ -x "$ghostty_bin" ]]; then
    "$ghostty_bin" +validate-config
fi

printf 'TERMINAL_TOOLCHAIN_OK\n'
