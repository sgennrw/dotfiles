#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/scripts/lib.sh"

printf "\033[1m=== SYNCING DOTFILES ===\033[0m\n\n"

if [ ! -t 0 ] || [ ! -t 1 ]; then
  printf "[ERROR] sync.sh must be run manually from an interactive terminal.\n" >&2
  exit 1
fi

groups=()
selected() { [[ " ${groups[*]} " == *" $1 "* ]]; }

select_sync_groups() {
  local selection
  local choice
  local -a choices

  while true; do
    printf '%s\n' "Select what to sync (space-separated):" \
      "  1) ~/.zshrc" \
      "  2) ~/.gitconfig" \
      "  3) ~/.config (except Git-ignored files)" \
      "  4) personal skills (agents/skills)" \
      "  a) all" \
      "  q) abort"
    read -r -p "Selection: " selection

    case "$selection" in
      q)
        printf '%s\n' "[ABORTED] No files were copied."
        exit 1
        ;;
      a) selection="1 2 3 4" ;;
    esac

    choices=()
    read -r -a choices <<< "$selection"
    if [ "${#choices[@]}" -eq 0 ]; then
      printf '%s\n\n' "[ERROR] Select at least one sync group."
      continue
    fi

    groups=()
    for choice in "${choices[@]}"; do
      case "$choice" in
        [1-4]) ;;
        *)
          printf '[ERROR] Unknown selection: %s\n\n' "$choice"
          continue 2
          ;;
      esac
      if selected "$choice"; then
        printf '[ERROR] Duplicate selection: %s\n\n' "$choice"
        continue 2
      fi
      groups+=("$choice")
    done
    return
  done
}

select_sync_groups

printf '%s' "Selected:"
selected 1 && printf ' ~/.zshrc'
selected 2 && printf ' ~/.gitconfig'
selected 3 && printf ' ~/.config'
selected 4 && printf ' ~/.agents'
printf '\n'

read -r -p "Type sync to copy the selected files into this repository: " confirmation
if [ "$confirmation" != "sync" ]; then
  printf "[ABORTED] No files were copied.\n"
  exit 1
fi

if selected 1; then
  if [ ! -f "$HOME/.zshrc" ]; then
    printf "[ERROR] required source file is missing: %s\n" "$HOME/.zshrc" >&2
    exit 1
  fi

  if grep -Eq '^[[:space:]]*(export[[:space:]]+)?[[:upper:]_][[:upper:][:digit:]_]*(TOKEN|API_KEY|SECRET|PASSWORD)[[:upper:][:digit:]_]*=' "$HOME/.zshrc"; then
    printf "[ERROR] ~/.zshrc contains a credential assignment; move it to local secret management before syncing.\n" >&2
    exit 1
  fi
fi

if selected 2 && [ ! -f "$HOME/.gitconfig" ]; then
  printf "[ERROR] required source file is missing: %s\n" "$HOME/.gitconfig" >&2
  exit 1
fi

# --- .zshrc ---
if selected 1; then
  copy_managed_file "$HOME/.zshrc" "$DOTFILES_DIR/zsh/.zshrc"
  printf "  [sync] ~/.zshrc\n"
fi

# --- .gitconfig ---
if selected 2; then
  copy_managed_file "$HOME/.gitconfig" "$DOTFILES_DIR/.gitconfig"
  printf "  [sync] ~/.gitconfig\n"
fi

# --- .config ---
if selected 3; then
  sync_config_entries "$HOME/.config" "$DOTFILES_DIR/.config"
  printf "  [sync] ~/.config (except Git-ignored files)\n"
fi

# --- agent skills ---
if selected 4; then
  printf "\n\033[1m=== SYNCING AGENTS ===\033[0m\n"
  assert_safe_path "$HOME/.agents/skills"
  if [ ! -d "$HOME/.agents/skills" ]; then
    printf '[ERROR] Required skills source directory is missing: %s\n' "$HOME/.agents/skills" >&2
    exit 1
  fi
  # Only names already in our personal folder are synced back from the machine.
  for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    source_skill="$HOME/.agents/skills/$skill_name"
    assert_safe_path "$source_skill"
    if [ ! -d "$source_skill" ] || [ -e "$source_skill/.git" ] || [ -e "$skill_dir/.git" ]; then
      printf '  [skip] %s (missing or Git-managed)\n' "$skill_name"
      continue
    fi
    sync_directory "$source_skill" "${skill_dir%/}" mirror
    printf "  [sync] ~/.agents/skills/%s (local)\n" "$skill_name"
  done
fi

# --- show what changed ---
printf "\n\033[1m=== CHANGES ===\033[0m\n"
git -C "$DOTFILES_DIR" --no-pager diff --stat
git -C "$DOTFILES_DIR" --no-pager status --short

printf "\nReview with: git diff\n"
printf "Then commit: git add -A && git commit -m \"chore: sync dotfiles\"\n"
