#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP="$(mktemp -d)"
TEST_CONTAINER=""
TEST_IMAGE="dotfiles-smoke-test-$(basename "$TEST_TEMP" | tr '[:upper:]' '[:lower:]')"
cleanup() {
  if [ -n "$TEST_CONTAINER" ]; then
    docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true
  fi
  docker image rm "$TEST_IMAGE" >/dev/null 2>&1 || true
  rm -rf "$TEST_TEMP"
}
trap cleanup EXIT

printf '=== DOTFILES SMOKE TEST ===\n'
docker build -t "$TEST_IMAGE" "$DOTFILES_DIR" --quiet
TEST_CONTAINER="$(docker create "$TEST_IMAGE" bash tests/smoke.sh)"
docker start -a "$TEST_CONTAINER"
TEST_EXIT="$(docker inspect --format '{{.State.ExitCode}}' "$TEST_CONTAINER")"
if [ "$TEST_EXIT" -ne 0 ]; then
  printf '[FAIL] Container checks exited with %s\n' "$TEST_EXIT" >&2
  exit 1
fi

# Preserve the /root/.config layout while checking extraction as well.
docker cp "$TEST_CONTAINER:/root" "$TEST_TEMP"
test -f "$TEST_TEMP/root/.config/nvim/init.lua"
test -f "$TEST_TEMP/root/.zshrc"
printf '=== ALL CHECKS PASSED ===\n'
