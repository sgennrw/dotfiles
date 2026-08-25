#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf "\033[1m=== SYNCING DOTFILES ===\033[0m\n\n"

# --- .zshrc ---
cp -f "$HOME/.zshrc" "$DOTFILES_DIR/zsh/.zshrc"
printf "  [sync] ~/.zshrc\n"

# --- .gitconfig ---
cp -f "$HOME/.gitconfig" "$DOTFILES_DIR/.gitconfig"
printf "  [sync] ~/.gitconfig\n"

# --- .config ---
cp -rf "$HOME/.config/karabiner" "$DOTFILES_DIR/.config/"
printf "  [sync] ~/.config/karabiner\n"

cp -rf "$HOME/.config/lazygit" "$DOTFILES_DIR/.config/"
printf "  [sync] ~/.config/lazygit\n"

cp -rf "$HOME/.config/nvim" "$DOTFILES_DIR/.config/"
printf "  [sync] ~/.config/nvim\n"

cp -rf "$HOME/.config/zed" "$DOTFILES_DIR/.config/"
printf "  [sync] ~/.config/zed\n"

# --- show what changed ---
printf "\n\033[1m=== CHANGES ===\033[0m\n"
git -C "$DOTFILES_DIR" diff --stat

printf "\nReview with: git diff\n"
printf "Then commit: git add -A && git commit -m \"chore: sync dotfiles\"\n"
