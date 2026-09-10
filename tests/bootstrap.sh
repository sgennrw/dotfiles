#!/usr/bin/env bash
set -euo pipefail

# Fixed-prefix fixtures must never replace the host's Homebrew executable.
if [ "${DOTFILES_TEST_CONTAINER:-}" != 1 ] || [ ! -f /.dockerenv ]; then
  printf 'bootstrap tests require the disposable Docker test container\n' >&2
  exit 1
fi

bootstrap_repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bootstrap_tmp="$(mktemp -d)"
mkdir -p /opt/homebrew/bin /usr/local/bin "$bootstrap_tmp/path"
for prefix in /opt/homebrew /usr/local; do
  if [ -e "$prefix/bin/brew" ]; then
    cp -p "$prefix/bin/brew" "$bootstrap_tmp/$(basename "$prefix").brew"
  fi
done
cleanup() {
  local prefix saved
  for prefix in /opt/homebrew /usr/local; do
    saved="$bootstrap_tmp/$(basename "$prefix").brew"
    if [ -f "$saved" ]; then
      cp -p "$saved" "$prefix/bin/brew"
    else
      rm -f "$prefix/bin/brew"
    fi
  done
  rm -rf "$bootstrap_tmp"
}
trap cleanup EXIT

cat > "$bootstrap_tmp/mock-brew" <<'MOCK'
#!/bin/bash
if [ "$1" = shellenv ]; then
  printf 'export PATH="%s:$PATH"\nexport DOTFILES_BREW_READY=1\n' "$(dirname "$0")"
  exit 0
fi
[ "${DOTFILES_BREW_READY:-}" = 1 ] || exit 99
printf '%s\n' "$*" >> "$DOTFILES_BREW_LOG"
case "$1" in
  list) exit 1 ;;
  install) exit 0 ;;
  *) exit 98 ;;
esac
MOCK
chmod +x "$bootstrap_tmp/mock-brew"

for prefix in "$bootstrap_tmp/path" /opt/homebrew/bin /usr/local/bin; do
  rm -f /opt/homebrew/bin/brew /usr/local/bin/brew "$bootstrap_tmp/path/brew"
  cp "$bootstrap_tmp/mock-brew" "$prefix/brew"
  bootstrap_path=/usr/bin:/bin
  if [ "$prefix" = "$bootstrap_tmp/path" ]; then
    bootstrap_path="$prefix:$bootstrap_path"
  fi
  env -u DOTFILES_BREW_READY PATH="$bootstrap_path" DOTFILES_BREW_LOG="$bootstrap_tmp/log" \
    /bin/bash -e -c 'source "$1/scripts/brew.sh"' bash "$bootstrap_repo" > /dev/null
  grep -qx 'install ripgrep' "$bootstrap_tmp/log"
  if grep -Eq 'install (television|nvm)$' "$bootstrap_tmp/log"; then
    printf 'Unexpected retired package installation\n' >&2
    exit 1
  fi
  rm "$bootstrap_tmp/log"
done

# A failed download can return valid shell text; that text must not execute.
rm -f /opt/homebrew/bin/brew /usr/local/bin/brew "$bootstrap_tmp/path/brew"
cat > "$bootstrap_tmp/path/curl" <<'MOCK'
#!/bin/bash
printf 'touch "%s"\n' "$DOTFILES_DOWNLOAD_MARKER"
exit 22
MOCK
chmod +x "$bootstrap_tmp/path/curl"
if env PATH="$bootstrap_tmp/path:/usr/bin:/bin" DOTFILES_DOWNLOAD_MARKER="$bootstrap_tmp/executed" \
  /bin/bash -e -c 'source "$1/scripts/brew.sh"' bash "$bootstrap_repo" > /dev/null; then
  printf 'Failed Homebrew download was accepted\n' >&2
  exit 1
fi
[ ! -e "$bootstrap_tmp/executed" ]
printf 'PASS: Homebrew PATH/prefix discovery, shellenv, packages and download failure\n'
