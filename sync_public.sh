#!/usr/bin/env bash
set -euo pipefail

PUBLIC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${DOTFILES_SOURCE:-$PUBLIC_ROOT/../dotfiles}"

if [[ ! -d "$SOURCE_ROOT/.git" ]]; then
  printf 'Source repository not found: %s\n' "$SOURCE_ROOT" >&2
  exit 1
fi

# Copy shared files, then remove machine-specific paths from the public copy.
cp "$SOURCE_ROOT/.tmux.conf" "$PUBLIC_ROOT/.tmux.conf"

sed \
  -e 's#git for-each-ref --format=#git for-each-ref --sort=-committerdate --format=#' \
  -e 's#/Users/applesucks#\$HOME#g' \
  -e 's#^source \$HOME/\(.*\)$#source "$HOME/\1"#' \
  -e '/^# Refresh zsh.s command lookup after fnm\/PNPM_HOME initialization\.$/d' \
  -e '/^rehash$/d' \
  "$SOURCE_ROOT/.zshrc" > "$PUBLIC_ROOT/.zshrc"
printf '# Refresh zsh'"'"'s command lookup after fnm/PNPM_HOME initialization.\nrehash\n' >> "$PUBLIC_ROOT/.zshrc"

perl -0pe 's#local tmux_bin = .*#local tmux_bin = "tmux"#; s#local tmux_session_picker = .*#local tmux_session_picker = "fish "#; s#local hyperkey_monitor_script =.*?(?=\n\n)#local hyperkey_monitor_script = wezterm.home_dir .. "/bin/hyperkey-monitor.sh"#s; s#cwd = "/Users/applesucks/[^\"]*"#cwd = wezterm.home_dir .. "/bin"#g' \
  "$SOURCE_ROOT/.wezterm.lua" > "$PUBLIC_ROOT/.wezterm.lua"

printf 'Synchronized public dotfiles from %s\n' "$SOURCE_ROOT"
