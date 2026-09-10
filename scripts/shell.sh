#!/usr/bin/env bash

source "$DOTFILES_DIR/scripts/lib.sh"

assert_safe_path "$HOME/.zshrc"
assert_safe_path "$HOME/.gitconfig"

printf "\n\033[1m=== OH-MY-ZSH ===\033[0m\n"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  printf "Installing ohmyzsh...\n"
  ohmyzsh_installer="$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || return 1
  KEEP_ZSHRC=yes sh -c "$ohmyzsh_installer" "" --unattended
  unset ohmyzsh_installer
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
copy_managed_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc" install
printf "Copied zsh/.zshrc -> ~/.zshrc\n"

printf "\n\033[1m=== DOTFILES: GITCONFIG ===\033[0m\n"
copy_managed_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig" install
printf "Copied .gitconfig -> ~/.gitconfig\n"

printf "\n\033[1m=== DOTFILES: CONFIG ===\033[0m\n"
mkdir -p "$HOME/.config"
sync_config_entries "$DOTFILES_DIR/.config" "$HOME/.config" install
printf "  [install] ~/.config (except Git-ignored files)\n"

printf "\n\033[1m=== MANUAL: ITERM2 ===\033[0m\n"
printf "See README.md for iTerm2 profile import and preferences setup.\n"
