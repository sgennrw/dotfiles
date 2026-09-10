#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/scripts/lib.sh"

printf "\033[1m=== SYNCING DOTFILES ===\033[0m\n\n"

if [ ! -t 0 ] || [ ! -t 1 ]; then
  printf "[ERROR] sync.sh must be run manually from an interactive terminal.\n" >&2
  exit 1
fi

select_sync_groups() {
  local selection
  local choice
  local -a choices

  while true; do
    printf '%s\n' "Select what to sync (space-separated):" \
      "  1) ~/.zshrc" \
      "  2) ~/.gitconfig" \
      "  3) ~/.config (all entries)" \
      "  4) ~/.agents (lock file and non-git skills)" \
      "  a) all" \
      "  q) abort"
    read -r -p "Selection: " selection

    case "$selection" in
      q)
        printf '%s\n' "[ABORTED] No files were copied."
        exit 1
        ;;
      a)
        sync_zshrc=1
        sync_gitconfig=1
        sync_config=1
        sync_agents=1
        return
        ;;
    esac

    choices=()
    read -r -a choices <<< "$selection"
    if [ "${#choices[@]}" -eq 0 ]; then
      printf '%s\n\n' "[ERROR] Select at least one sync group."
      continue
    fi

    sync_zshrc=0
    sync_gitconfig=0
    sync_config=0
    sync_agents=0
    for choice in "${choices[@]}"; do
      case "$choice" in
        1)
          if [ "$sync_zshrc" -eq 1 ]; then
            printf '%s\n\n' "[ERROR] Duplicate selection: 1"
            continue 2
          fi
          sync_zshrc=1
          ;;
        2)
          if [ "$sync_gitconfig" -eq 1 ]; then
            printf '%s\n\n' "[ERROR] Duplicate selection: 2"
            continue 2
          fi
          sync_gitconfig=1
          ;;
        3)
          if [ "$sync_config" -eq 1 ]; then
            printf '%s\n\n' "[ERROR] Duplicate selection: 3"
            continue 2
          fi
          sync_config=1
          ;;
        4)
          if [ "$sync_agents" -eq 1 ]; then
            printf '%s\n\n' "[ERROR] Duplicate selection: 4"
            continue 2
          fi
          sync_agents=1
          ;;
        *)
          printf '[ERROR] Unknown selection: %s\n\n' "$choice"
          continue 2
          ;;
      esac
    done
    return
  done
}

sync_zshrc=0
sync_gitconfig=0
sync_config=0
sync_agents=0
select_sync_groups

printf '%s' "Selected:"
[ "$sync_zshrc" -eq 1 ] && printf ' ~/.zshrc'
[ "$sync_gitconfig" -eq 1 ] && printf ' ~/.gitconfig'
[ "$sync_config" -eq 1 ] && printf ' ~/.config'
[ "$sync_agents" -eq 1 ] && printf ' ~/.agents'
printf '\n'

read -r -p "Type sync to copy the selected files into this repository: " confirmation
if [ "$confirmation" != "sync" ]; then
  printf "[ABORTED] No files were copied.\n"
  exit 1
fi

if [ "$sync_zshrc" -eq 1 ]; then
  if [ ! -f "$HOME/.zshrc" ]; then
    printf "[ERROR] required source file is missing: %s\n" "$HOME/.zshrc" >&2
    exit 1
  fi

  if grep -Eq '^[[:space:]]*(export[[:space:]]+)?[[:upper:]_][[:upper:][:digit:]_]*(TOKEN|API_KEY|SECRET|PASSWORD)[[:upper:][:digit:]_]*=' "$HOME/.zshrc"; then
    printf "[ERROR] ~/.zshrc contains a credential assignment; move it to local secret management before syncing.\n" >&2
    exit 1
  fi
fi

if [ "$sync_gitconfig" -eq 1 ] && [ ! -f "$HOME/.gitconfig" ]; then
  printf "[ERROR] required source file is missing: %s\n" "$HOME/.gitconfig" >&2
  exit 1
fi

# --- .zshrc ---
if [ "$sync_zshrc" -eq 1 ]; then
  cp -f "$HOME/.zshrc" "$DOTFILES_DIR/zsh/.zshrc"
  printf "  [sync] ~/.zshrc\n"
fi

# --- .gitconfig ---
if [ "$sync_gitconfig" -eq 1 ]; then
  cp -f "$HOME/.gitconfig" "$DOTFILES_DIR/.gitconfig"
  printf "  [sync] ~/.gitconfig\n"
fi

# --- .config ---
if [ "$sync_config" -eq 1 ]; then
  sync_config_entries "$HOME/.config" "$DOTFILES_DIR/.config"
  printf "  [sync] ~/.config (all entries)\n"
fi

# --- agent skills ---
if [ "$sync_agents" -eq 1 ]; then
  printf "\n\033[1m=== SYNCING AGENTS ===\033[0m\n"

  if [ -f "$HOME/.agents/.skill-lock.json" ]; then
    cp -f "$HOME/.agents/.skill-lock.json" "$DOTFILES_DIR/agents/"
    printf "  [sync] ~/.agents/.skill-lock.json\n"
  fi

  is_lock_managed_skill() {
    grep -Fq "\"$1\":" "$DOTFILES_DIR/agents/.skill-lock.json"
  }

  for skill_dir in "$HOME/.agents/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    # Git repos self-update; lock-managed skills are restored by the CLI.
    if [ -d "$skill_dir/.git" ]; then
      printf "  [skip] ~/.agents/skills/%s (git repo)\n" "$skill_name"
      continue
    fi
    if is_lock_managed_skill "$skill_name"; then
      printf "  [skip] ~/.agents/skills/%s (lock-managed)\n" "$skill_name"
      continue
    fi
    sync_directory \
      "${skill_dir%/}" \
      "$DOTFILES_DIR/agents/skills/$skill_name"
    printf "  [sync] ~/.agents/skills/%s (local)\n" "$skill_name"
  done

  for repo_skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
    [ -d "$repo_skill_dir" ] || continue
    skill_name="$(basename "$repo_skill_dir")"
    if is_lock_managed_skill "$skill_name"; then
      continue
    fi
    if [ ! -d "$HOME/.agents/skills/$skill_name" ]; then
      rm -rf "$repo_skill_dir"
      printf "  [remove] agents/skills/%s (not installed)\n" "$skill_name"
    fi
  done
fi

# --- show what changed ---
printf "\n\033[1m=== CHANGES ===\033[0m\n"
git -C "$DOTFILES_DIR" diff --stat

printf "\nReview with: git diff\n"
printf "Then commit: git add -A && git commit -m \"chore: sync dotfiles\"\n"
