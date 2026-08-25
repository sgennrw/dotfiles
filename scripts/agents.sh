#!/usr/bin/env bash

source "$DOTFILES_DIR/scripts/lib.sh"

printf "\n\033[1m=== AGENTS: SKILLS ===\033[0m\n"

mkdir -p "$HOME/.agents/skills"

# --- restore non-git skills from repo ---
if [ -d "$DOTFILES_DIR/agents/skills" ]; then
  for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    sync_directory \
      "${skill_dir%/}" \
      "$HOME/.agents/skills/$skill_name"
    printf "  [install] ~/.agents/skills/%s\n" "$skill_name"
  done
fi

# --- restore skill-lock ---
if [ -f "$DOTFILES_DIR/agents/.skill-lock.json" ]; then
  cp -f "$DOTFILES_DIR/agents/.skill-lock.json" "$HOME/.agents/.skill-lock.json"
  printf "  [install] ~/.agents/.skill-lock.json\n"
fi

# --- superpowers: clone if not present ---
printf "\n\033[1m=== AGENTS: SUPERPOWERS ===\033[0m\n"

SUPERPOWERS_DIR="$HOME/.agents/skills/superpowers"

if [ ! -d "$SUPERPOWERS_DIR/.git" ]; then
  printf "Cloning superpowers...\n"
  git clone https://github.com/anomalyco/superpowers.git "$SUPERPOWERS_DIR"
else
  printf "  [skip] superpowers already present (run git pull inside to update)\n"
fi
