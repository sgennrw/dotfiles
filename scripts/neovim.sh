#!/usr/bin/env bash

printf "\n\033[1m=== NEOVIM / VIMRC ===\033[0m\n"

if [ ! -d "$HOME/.vim_runtime" ]; then
  printf "Cloning amix/vimrc...\n"
  git clone --depth=1 https://github.com/amix/vimrc.git "$HOME/.vim_runtime"
  sh "$HOME/.vim_runtime/install_awesome_vimrc.sh"
else
  printf "  [skip] ~/.vim_runtime already present\n"
fi

printf "Writing ~/.config/nvim/init.vim...\n"
mkdir -p "$HOME/.config/nvim"

if ! grep -q "vim_runtime" "$HOME/.config/nvim/init.vim" 2>/dev/null; then
  cat >> "$HOME/.config/nvim/init.vim" <<'EOF'
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
EOF
  printf "Bridge config written to ~/.config/nvim/init.vim\n"
else
  printf "  [skip] bridge config already present in init.vim\n"
fi
