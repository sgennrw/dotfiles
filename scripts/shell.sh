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
cp -rf "$DOTFILES_DIR/.config/karabiner" "$HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/lazygit"   "$HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/nvim"      "$HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/zed"       "$HOME/.config/"
printf "Copied .config/* -> ~/.config/\n"

printf "\n\033[1m=== MANUAL: ITERM2 SETUP ===\033[0m\n"
printf "[MANUAL] iTerm2 Profile Import:\n"
printf "  1. Open iTerm2\n"
printf "  2. Go to Preferences > Profiles\n"
printf "  3. On the sidebar, click 'Other Actions' > 'Import JSON Profiles'\n"
printf "  4. Select: %s/iterm2/iterm2-profile.json\n" "$DOTFILES_DIR"
printf "  5. Remove the old Default profile\n"
printf "\n"
printf "[MANUAL] iTerm2 Preferences:\n"
printf "  Preferences > Appearance > General\n"
printf "    Theme: Minimal | Tab bar: Top | Status bar: Bottom\n"
printf "  Preferences > Appearance > Tabs\n"
printf "    [x] Show tab bar even when there is only one tab\n"
printf "  Preferences > Keys > Hotkey\n"
printf "    [x] Show/hide all windows with system-wide hotkey  Hotkey: Alt+Space\n"
