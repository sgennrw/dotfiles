#!/usr/bin/env bash

printf "\n\033[1m=== HOMEBREW ===\033[0m\n"

dotfiles_find_brew() {
  command -v brew 2>/dev/null && return
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

if ! brew_bin="$(dotfiles_find_brew)"; then
  printf "Installing Homebrew...\n"
  # Keep download and execution separate so a failed download cannot look successful.
  brew_installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" || return 1
  /bin/bash -c "$brew_installer" || return 1
  unset brew_installer
  brew_bin="$(dotfiles_find_brew)" || {
    printf 'Homebrew installation finished but brew could not be found.\n' >&2
    return 1
  }
else
  printf "Homebrew already installed, skipping.\n"
fi

brew_environment="$("$brew_bin" shellenv)" || return 1
eval "$brew_environment"
unset brew_bin brew_environment

printf "\n\033[1m=== BREW PACKAGES ===\033[0m\n"

CASKS=(
  iterm2
  raycast
  obsidian
  zed
  karabiner-elements
  dbeaver-community
  colemak-dh
)

FORMULAE=(
  neovim
  node
  bat
  ripgrep
  git-delta
  fzf
  lazygit
  pyenv
  pnpm
  bun
  n
  rust
  jesseduffield/lazydocker/lazydocker
  docker
  docker-compose
  colima
)

printf "Installing cask apps...\n"
for cask in "${CASKS[@]}"; do
  brew list --cask "$cask" &>/dev/null || brew install --cask "$cask"
done

printf "Installing formulae...\n"
for formula in "${FORMULAE[@]}"; do
  brew list "${formula##*/}" &>/dev/null || brew install "$formula"
done
