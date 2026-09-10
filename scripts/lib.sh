#!/usr/bin/env bash

# Refuse symlinks anywhere along a managed path, including parent directories.
assert_safe_path() {
  local path="$1"
  case "$path" in
    /*) ;;
    *) printf '[ERROR] Expected an absolute path: %s\n' "$path" >&2; return 1 ;;
  esac
  while [ "$path" != / ]; do
    if [ -L "$path" ]; then
      printf '[ERROR] Refusing managed symlink: %s\n' "$path" >&2
      return 1
    fi
    path="$(dirname "$path")"
  done
}

assert_safe_tree() {
  assert_safe_path "$1" || return 1
  if [ -d "$1" ] && [ -n "$(find "$1" -name .git -prune -o -type l -print)" ]; then
    printf '[ERROR] Refusing symlinks inside managed directory: %s\n' "$1" >&2
    return 1
  fi
}

# One backup directory per installer invocation; mirror paths relative to HOME.
backup_existing() {
  local path="$1"
  local relative
  assert_safe_path "$path" || return 1
  [ -e "$path" ] || return 0
  case "$path" in
    "$HOME"/*) relative="${path#"$HOME"/}" ;;
    *) printf '[ERROR] Backup target is outside home: %s\n' "$path" >&2; return 1 ;;
  esac
  if [ -z "${DOTFILES_BACKUP_DIR:-}" ]; then
    assert_safe_path "$HOME/.local/state/dotfiles-backups" || return 1
    mkdir -p "$HOME/.local/state/dotfiles-backups" || return 1
    DOTFILES_BACKUP_DIR="$(mktemp -d "$HOME/.local/state/dotfiles-backups/install-$(date +%Y%m%d-%H%M%S)-XXXXXX")" || return 1
    printf '[backup] Existing settings saved under %s\n' "$DOTFILES_BACKUP_DIR"
  fi
  mkdir -p "$(dirname "$DOTFILES_BACKUP_DIR/$relative")" || return 1
  cp -pR "$path" "$DOTFILES_BACKUP_DIR/$relative"
}

copy_managed_file() {
  local source_file="$1" destination_file="$2" mode="${3:-sync}"
  assert_safe_path "$source_file" && assert_safe_path "$destination_file" || return 1
  if [ ! -f "$source_file" ] || { [ -e "$destination_file" ] && [ ! -f "$destination_file" ]; }; then
    printf '[ERROR] Managed file has missing source or incompatible destination: %s\n' "$source_file" >&2
    return 1
  fi
  if [ "$mode" = install ]; then
    backup_existing "$destination_file" || return 1
  fi
  mkdir -p "$(dirname "$destination_file")" || return 1
  cp -p "$source_file" "$destination_file"
}

sync_directory() {
  local source_dir="$1" destination_dir="$2" mode="${3:-merge}"
  local -a options=(-a --exclude=.git)
  assert_safe_tree "$source_dir" && assert_safe_tree "$destination_dir" || return 1
  if [ ! -d "$source_dir" ] || { [ -e "$destination_dir" ] && [ ! -d "$destination_dir" ]; }; then
    printf '[ERROR] Invalid directory transfer: %s -> %s\n' "$source_dir" "$destination_dir" >&2
    return 1
  fi
  if ! command -v rsync >/dev/null 2>&1; then
    printf '[ERROR] rsync is required to synchronize %s\n' "$source_dir" >&2
    return 1
  fi
  [ "$mode" != mirror ] || options+=(--delete)
  mkdir -p "$destination_dir" || return 1
  rsync "${options[@]}" "$source_dir/" "$destination_dir/"
}

sync_config_entries() {
  local source_root="$1" destination_root="$2" mode="${3:-sync}"
  local source_file entry
  assert_safe_path "$source_root" && assert_safe_path "$destination_root" || return 1
  [ -d "$source_root" ] || return 0
  git -C "$DOTFILES_DIR" rev-parse --git-dir >/dev/null || return 1
  while IFS= read -r -d '' source_file; do
    entry="${source_file#"$source_root"/}"
    # Map live paths to their repository location before checking ignore rules.
    if git -C "$DOTFILES_DIR" check-ignore --no-index -q -- ".config/$entry"; then
      continue
    else
      [ "$?" -eq 1 ] || return 1
    fi
    copy_managed_file "$source_file" "$destination_root/$entry" "$mode" || return 1
  done < <(find "$source_root" -name .git -prune -o \( -type f -o -type l \) -print0)
}
