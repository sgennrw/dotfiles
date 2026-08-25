#!/usr/bin/env bash
set -e

IMAGE="dotfiles-smoke-test"
CONTAINER="dotfiles-smoke-test-run"
TMPDIR_CHECK=""

cleanup() {
  if [ -n "$TMPDIR_CHECK" ]; then
    rm -rf "$TMPDIR_CHECK"
  fi
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}

trap cleanup EXIT

printf "\033[1m=== DOTFILES SMOKE TEST ===\033[0m\n\n"

printf "[1/3] Building Docker image...\n"
docker build -t "$IMAGE" . --quiet

printf "[2/3] Running install.sh in container...\n"
docker rm -f "$CONTAINER" 2>/dev/null || true

set +e
docker run --name "$CONTAINER" "$IMAGE" bash install.sh
EXIT_CODE=$?
set -e

if [ "$EXIT_CODE" -ne 0 ]; then
  printf "\n[FAIL] install.sh exited with code %d\n" "$EXIT_CODE"
  docker rm -f "$CONTAINER" 2>/dev/null || true
  exit 1
fi

printf "\n[3/3] Checking expected files...\n"

# Copy the home dir out of the stopped container for inspection
TMPDIR_CHECK="$(mktemp -d)"
docker cp "$CONTAINER:/root" "$TMPDIR_CHECK"
HOME_CHECK="$TMPDIR_CHECK/root"

FAILURES=0

check_file() {
  local path="$1"          # relative to container /root
  local description="$2"
  if [ -f "$HOME_CHECK/$path" ]; then
    printf "  [pass] %s\n" "$description"
  else
    printf "  [FAIL] %s — not found at ~/%s\n" "$description" "$path"
    FAILURES=$((FAILURES + 1))
  fi
}

check_contains() {
  local path="$1"
  local pattern="$2"
  local description="$3"
  if grep -q "$pattern" "$HOME_CHECK/$path" 2>/dev/null; then
    printf "  [pass] %s\n" "$description"
  else
    printf "  [FAIL] %s — '%s' not found in ~/%s\n" "$description" "$pattern" "$path"
    FAILURES=$((FAILURES + 1))
  fi
}

check_command_fails() {
  local description="$1"
  shift

  if "$@"; then
    printf "  [FAIL] %s — command unexpectedly succeeded\n" "$description"
    FAILURES=$((FAILURES + 1))
  else
    printf "  [pass] %s\n" "$description"
  fi
}

check_file     ".zshrc"                ".zshrc copied to ~/"
check_contains ".zshrc"    "alias lb"  ".zshrc contains lb alias"
check_contains ".zshrc"    "alias ws"  ".zshrc contains ws alias"
check_file     ".gitconfig"            ".gitconfig copied to ~/"
check_file     ".config/nvim/init.lua" "nvim init.lua copied"
check_command_fails "sync.sh rejects non-interactive execution" \
  docker run --rm "$IMAGE" bash -c 'mkdir -p /root/.agents/skills/example; cp /dotfiles/zsh/.zshrc /root/.zshrc; cp /dotfiles/.gitconfig /root/.gitconfig; cd /dotfiles && bash sync.sh </dev/null'
check_command_fails "sync.sh rejects shell credentials" \
  docker run --rm "$IMAGE" bash -c 'printf "export TEST_API_KEY=value\\n" > /root/.zshrc; cd /dotfiles; printf "sync\\n" | script -e -q -c "bash sync.sh" /dev/null'

docker run --rm "$IMAGE" bash -c 'set -e; bash /dotfiles/scripts/ssh.sh >/dev/null; bash /dotfiles/scripts/ssh.sh >/dev/null; test "$(grep -c "^Host github.com-labs$" /root/.ssh/config)" -eq 1; test "$(grep -c "^Host github.com-workspaces$" /root/.ssh/config)" -eq 1'

docker run --rm "$IMAGE" bash -c 'set -e; mkdir -p /root/.config/nvim; printf stale > /dotfiles/.config/nvim/stale.txt; printf current > /root/.config/nvim/current.txt; cp /dotfiles/zsh/.zshrc /root/.zshrc; cp /dotfiles/.gitconfig /root/.gitconfig; cd /dotfiles; printf "sync\\n" | script -e -q -c "bash sync.sh" /dev/null >/dev/null; test ! -e /dotfiles/.config/nvim/stale.txt; test -f /dotfiles/.config/nvim/current.txt'

docker run --rm "$IMAGE" bash -c 'set -e; mkdir -p /dotfiles/.config/future-tool; printf configured > /dotfiles/.config/future-tool/settings; DOTFILES_DIR=/dotfiles bash /dotfiles/scripts/shell.sh >/dev/null; test -f /root/.config/future-tool/settings'

docker run --rm "$IMAGE" bash -c 'set -e; mkdir -p /root/.agents/skills/local-skill; printf keep > /root/.agents/skills/local-skill/marker; bash /dotfiles/install.sh >/dev/null; test -f /root/.agents/skills/local-skill/marker'

printf "\n"
if [ "$FAILURES" -eq 0 ]; then
  printf "\033[1m=== ALL CHECKS PASSED ===\033[0m\n"
  exit 0
else
  printf "\033[1m=== %d CHECK(S) FAILED ===\033[0m\n" "$FAILURES"
  exit 1
fi
