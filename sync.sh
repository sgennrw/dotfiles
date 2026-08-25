#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/scripts/lib.sh"

printf "\033[1m=== SYNCING DOTFILES ===\033[0m\n\n"

if [ ! -t 0 ] || [ ! -t 1 ]; then
  printf "[ERROR] sync.sh must be run manually from an interactive terminal.\n" >&2
  exit 1
fi

read -r -p "Type sync to copy live dotfiles into this repository: " confirmation
if [ "$confirmation" != "sync" ]; then
  printf "[ABORTED] No files were copied.\n"
  exit 1
fi

if grep -Eq '^[[:space:]]*(export[[:space:]]+)?[[:upper:]_][[:upper:][:digit:]_]*(TOKEN|API_KEY|SECRET|PASSWORD)[[:upper:][:digit:]_]*=' "$HOME/.zshrc"; then
  printf "[ERROR] ~/.zshrc contains a credential assignment; move it to local secret management before syncing.\n" >&2
  exit 1
fi

for required_file in "$HOME/.zshrc" "$HOME/.gitconfig"; do
  if [ ! -f "$required_file" ]; then
    printf "[ERROR] required source file is missing: %s\n" "$required_file" >&2
    exit 1
  fi
done

# --- .zshrc ---
cp -f "$HOME/.zshrc" "$DOTFILES_DIR/zsh/.zshrc"
printf "  [sync] ~/.zshrc\n"

# --- .gitconfig ---
cp -f "$HOME/.gitconfig" "$DOTFILES_DIR/.gitconfig"
printf "  [sync] ~/.gitconfig\n"

# --- .config ---
sync_config_entries "$HOME/.config" "$DOTFILES_DIR/.config"
printf "  [sync] ~/.config (all entries)\n"

# --- agents skills (skip git repos — they self-update via git pull) ---
printf "\n\033[1m=== SYNCING AGENTS ===\033[0m\n"

if [ -f "$HOME/.agents/.skill-lock.json" ]; then
  cp -f "$HOME/.agents/.skill-lock.json" "$DOTFILES_DIR/agents/"
  printf "  [sync] ~/.agents/.skill-lock.json\n"
fi

for skill_dir in "$HOME/.agents/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"
  # skip git repos — they are managed by git pull, not by this sync
  if [ -d "$skill_dir/.git" ]; then
    printf "  [skip] ~/.agents/skills/%s (git repo)\n" "$skill_name"
    continue
  fi
  sync_directory \
    "${skill_dir%/}" \
    "$DOTFILES_DIR/agents/skills/$skill_name"
  printf "  [sync] ~/.agents/skills/%s\n" "$skill_name"
done

for repo_skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
  [ -d "$repo_skill_dir" ] || continue
  skill_name="$(basename "$repo_skill_dir")"
  if [ ! -d "$HOME/.agents/skills/$skill_name" ]; then
    rm -rf "$repo_skill_dir"
    printf "  [remove] agents/skills/%s (not installed)\n" "$skill_name"
  fi
done

# --- show what changed ---
printf "\n\033[1m=== CHANGES ===\033[0m\n"
git -C "$DOTFILES_DIR" diff --stat

printf "\nReview with: git diff\n"
printf "Then commit: git add -A && git commit -m \"chore: sync dotfiles\"\n"
