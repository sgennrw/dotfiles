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
for config_dir in karabiner lazygit nvim zed; do
  if [ -d "$HOME/.config/$config_dir" ]; then
    cp -rf "$HOME/.config/$config_dir" "$DOTFILES_DIR/.config/"
    printf "  [sync] ~/.config/%s\n" "$config_dir"
  else
    printf "  [skip] ~/.config/%s (not found)\n" "$config_dir"
  fi
done

# --- agents skills (skip git repos — they self-update via git pull) ---
printf "\n\033[1m=== SYNCING AGENTS ===\033[0m\n"

if [ -f "$HOME/.agents/.skill-lock.json" ]; then
  cp -f "$HOME/.agents/.skill-lock.json" "$DOTFILES_DIR/agents/"
  printf "  [sync] ~/.agents/.skill-lock.json\n"
fi

for skill_dir in "$HOME/.agents/skills"/*/; do
  skill_name="$(basename "$skill_dir")"
  # skip git repos — they are managed by git pull, not by this sync
  if [ -d "$skill_dir/.git" ]; then
    printf "  [skip] ~/.agents/skills/%s (git repo)\n" "$skill_name"
    continue
  fi
  cp -rf "${skill_dir%/}" "$DOTFILES_DIR/agents/skills/"
  printf "  [sync] ~/.agents/skills/%s\n" "$skill_name"
done

# --- show what changed ---
printf "\n\033[1m=== CHANGES ===\033[0m\n"
git -C "$DOTFILES_DIR" diff --stat

printf "\nReview with: git diff\n"
printf "Then commit: git add -A && git commit -m \"chore: sync dotfiles\"\n"
