#!/usr/bin/env bash

printf "\n\033[1m=== OH-MY-ZSH ===\033[0m\n"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  printf "Installing ohmyzsh...\n"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  printf "ohmyzsh already installed, skipping.\n"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

printf "\n\033[1m=== ZSH PLUGINS ===\033[0m\n"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  printf "Cloning zsh-autosuggestions...\n"
  git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  printf "  [skip] zsh-autosuggestions already present\n"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  printf "Cloning zsh-syntax-highlighting...\n"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
  printf "  [skip] zsh-syntax-highlighting already present\n"
fi

printf "\n\033[1m=== DOTFILES: ZSHRC ===\033[0m\n"
cp -f "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
printf "Copied zsh/.zshrc -> ~/.zshrc\n"

printf "\n\033[1m=== DOTFILES: GITCONFIG ===\033[0m\n"
cp -f "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
printf "Copied .gitconfig -> ~/.gitconfig\n"

printf "\n\033[1m=== DOTFILES: CONFIG ===\033[0m\n"
mkdir -p "$HOME/.config"
for config_dir in karabiner lazygit nvim zed; do
  if [ -d "$DOTFILES_DIR/.config/$config_dir" ]; then
    cp -rf "$DOTFILES_DIR/.config/$config_dir" "$HOME/.config/"
    printf "  [install] ~/.config/%s\n" "$config_dir"
  fi
done
cp -f "$DOTFILES_DIR/.config/labs.gitconfig"       "$HOME/.config/"
cp -f "$DOTFILES_DIR/.config/workspaces.gitconfig" "$HOME/.config/"
printf "  [install] ~/.config/labs.gitconfig\n"
printf "  [install] ~/.config/workspaces.gitconfig\n"

printf "\n\033[1m=== MANUAL: ITERM2 ===\033[0m\n"
printf "See README.md for iTerm2 profile import and preferences setup.\n"
