#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTFILES_DIR/scripts/brew.sh"
source "$DOTFILES_DIR/scripts/shell.sh"
source "$DOTFILES_DIR/scripts/neovim.sh"
source "$DOTFILES_DIR/scripts/docker.sh"
source "$DOTFILES_DIR/scripts/ssh.sh"
source "$DOTFILES_DIR/scripts/agents.sh"

printf "\n\033[1m=== SETUP COMPLETE ===\033[0m\n"
printf "Restart your terminal for all changes to take effect.\n"
