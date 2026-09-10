#!/usr/bin/env bash

source "$DOTFILES_DIR/scripts/lib.sh"

printf "\n\033[1m=== AGENTS: SKILLS ===\033[0m\n"

assert_safe_path "$DOTFILES_DIR/.agents/skills"
(
  cd "$DOTFILES_DIR" || exit 1
  npx --yes skills@1.5.23 experimental_install || exit 1
  # The experimental command may log a restore failure without failing itself.
  node <<'NODE'
const fs = require('fs');
for (const name of Object.keys(JSON.parse(fs.readFileSync('skills-lock.json')).skills)) {
  if (!fs.existsSync(`.agents/skills/${name}/SKILL.md`)) {
    throw new Error(`Skill was not restored: ${name}`);
  }
}
NODE
)

assert_safe_path "$HOME/.agents/skills"
mkdir -p "$HOME/.agents/skills"

# Keep personal and third-party skill names distinct.
for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"
  if [ -d "$DOTFILES_DIR/.agents/skills/$skill_name" ]; then
    printf '[ERROR] Skill exists in both personal and installed folders: %s\n' "$skill_name" >&2
    return 1
  fi
done

# Skills CLI installs into .agents/skills; personal skills live in agents/skills.
for skill_dir in "$DOTFILES_DIR/.agents/skills"/*/ "$DOTFILES_DIR/agents/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"
  if [ -e "$skill_dir/.git" ] || [ -e "$HOME/.agents/skills/$skill_name/.git" ]; then
    printf '  [skip] %s (Git repository)\n' "$skill_name"
    continue
  fi
  backup_existing "$HOME/.agents/skills/$skill_name"
  sync_directory "${skill_dir%/}" "$HOME/.agents/skills/$skill_name"
  printf '  [install] ~/.agents/skills/%s\n' "$skill_name"
done

# --- superpowers: clone if not present ---
printf "\n\033[1m=== AGENTS: SUPERPOWERS ===\033[0m\n"

SUPERPOWERS_DIR="$HOME/.agents/skills/superpowers"

assert_safe_path "$SUPERPOWERS_DIR"
if [ ! -e "$SUPERPOWERS_DIR/.git" ]; then
  printf "Cloning superpowers...\n"
  git clone https://github.com/anomalyco/superpowers.git "$SUPERPOWERS_DIR"
else
  printf "  [skip] superpowers already present (run git pull inside to update)\n"
fi
