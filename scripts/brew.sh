#!/usr/bin/env bash

printf "\n\033[1m=== HOMEBREW ===\033[0m\n"

if ! command -v brew &>/dev/null; then
  printf "Installing Homebrew...\n"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
  printf "Homebrew already installed, skipping.\n"
fi

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
  nvm
  bat
  git-delta
  fzf
  lazygit
)

printf "Installing cask apps...\n"
for cask in "${CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null; then
    printf "  [skip] %s already installed\n" "$cask"
  else
    printf "  [install] %s\n" "$cask"
    brew install --cask "$cask"
  fi
done

printf "Installing formulae...\n"
for formula in "${FORMULAE[@]}"; do
  if brew list "$formula" &>/dev/null; then
    printf "  [skip] %s already installed\n" "$formula"
  else
    printf "  [install] %s\n" "$formula"
    brew install "$formula"
  fi
done

printf "Installing lazydocker tap...\n"
if ! brew list lazydocker &>/dev/null; then
  brew install jesseduffield/lazydocker/lazydocker
else
  printf "  [skip] lazydocker already installed\n"
fi

printf "Installing docker + colima...\n"
for formula in docker docker-compose colima; do
  if brew list "$formula" &>/dev/null; then
    printf "  [skip] %s already installed\n" "$formula"
  else
    printf "  [install] %s\n" "$formula"
    brew install "$formula"
  fi
done
