#!/usr/bin/env bash

sync_directory() {
  local source_dir="$1"
  local destination_dir="$2"

  if ! command -v rsync >/dev/null 2>&1; then
    printf "[ERROR] rsync is required to synchronize %s\n" "$source_dir" >&2
    return 1
  fi

  mkdir -p "$destination_dir"
  rsync -a --delete "$source_dir/" "$destination_dir/"
}

sync_config_entries() {
  local source_root="$1"
  local destination_root="$2"
  local had_nullglob=1
  local had_dotglob=1
  local source_path
  local entry_name
  local -a entries

  shopt -q nullglob && had_nullglob=0
  shopt -q dotglob && had_dotglob=0
  shopt -s nullglob dotglob
  entries=("$source_root"/*)
  (( had_nullglob == 0 )) || shopt -u nullglob
  (( had_dotglob == 0 )) || shopt -u dotglob

  mkdir -p "$destination_root"
  for source_path in "${entries[@]}"; do
    entry_name="$(basename "$source_path")"
    if [ -d "$source_path" ]; then
      sync_directory "$source_path" "$destination_root/$entry_name"
    else
      cp -f "$source_path" "$destination_root/$entry_name"
    fi
  done
}
