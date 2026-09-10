#!/usr/bin/env bash
set -euo pipefail
if [ "${DOTFILES_TEST_CONTAINER:-}" != 1 ] || [ ! -f /.dockerenv ]; then
  printf 'smoke tests require the disposable Docker test container\n' >&2
  exit 1
fi
cd /dotfiles
trap 'printf "[FAIL] line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

fail() { printf '[FAIL] %s\n' "$*" >&2; exit 1; }
expect_failure() {
  if "$@"; then fail "Command unexpectedly succeeded: $*"; fi
}
run_sync() {
  printf '%s\n' "$1" | script -e -q -c "bash /dotfiles/sync.sh" /dev/null
}

for script_file in install.sh sync.sh test.sh scripts/*.sh tests/*.sh; do
  bash -n "$script_file"
done
zsh -n zsh/.zshrc
bash tests/bootstrap.sh

# The repository in the image has no host Git metadata.
git init -q
git -c user.name=test -c user.email=test@example.invalid add -A
git -c user.name=test -c user.email=test@example.invalid commit -qm baseline

# A fresh clone contains the project lock but no downloaded skills.
test -f skills-lock.json
test ! -d .agents/skills
expect_failure env SKILLS_STUB_FAIL=1 bash -e -c 'DOTFILES_DIR=/dotfiles; source scripts/agents.sh'
expect_failure env SKILLS_STUB_SKIP=1 bash -e -c 'DOTFILES_DIR=/dotfiles; source scripts/agents.sh'
test ! -d /root/.agents/skills

mkdir -p /root/.config/zed/prompts /root/.config/karabiner/automatic_backups \
  /root/.config/nvim /root/.agents/skills/unrelated
printf 'live prompts' > /root/.config/zed/prompts/marker
printf 'local history' > /root/.config/karabiner/automatic_backups/marker
printf 'unmanaged nvim file' > /root/.config/nvim/local.txt
printf 'local skill' > /root/.agents/skills/unrelated/SKILL.md
printf 'existing global lock' > /root/.agents/.skill-lock.json
printf 'original zshrc' > /root/.zshrc
printf 'original gitconfig' > /root/.gitconfig

# Ignore rules also protect live data when ignored files exist in the repo.
mkdir -p .config/zed/prompts .config/karabiner/automatic_backups .config/new-tool
printf 'old prompts' > .config/zed/prompts/marker
printf 'old history' > .config/karabiner/automatic_backups/marker
printf 'new config' > '.config/new-tool/settings with spaces'
printf 'ignored backup' > .config/new-tool/settings.bak

bash install.sh > /tmp/install-first.log
git check-ignore -q .agents/skills/find-skills/SKILL.md
first_key="$(sha256sum /root/.ssh/id_ed25519_labs)"
bash install.sh > /tmp/install-second.log
test "$first_key" = "$(sha256sum /root/.ssh/id_ed25519_labs)"
test "$(grep -c '^Host github.com-labs$' /root/.ssh/config)" -eq 1
test "$(grep -c '^Host github.com-workspaces$' /root/.ssh/config)" -eq 1
test "$(cat /root/.config/zed/prompts/marker)" = 'live prompts'
test "$(cat /root/.config/karabiner/automatic_backups/marker)" = 'local history'
test "$(cat /root/.config/nvim/local.txt)" = 'unmanaged nvim file'
test "$(cat /root/.agents/skills/unrelated/SKILL.md)" = 'local skill'
test "$(cat '/root/.config/new-tool/settings with spaces')" = 'new config'
test ! -e /root/.config/new-tool/settings.bak
test "$(find /root/.local/state/dotfiles-backups -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 2
grep -rl 'original zshrc' /root/.local/state/dotfiles-backups >/dev/null
grep -rl 'original gitconfig' /root/.local/state/dotfiles-backups >/dev/null
test "$(cat /root/.agents/.skill-lock.json)" = 'existing global lock'
for skill_dir in .agents/skills/*/ agents/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  diff -r "$skill_dir" "/root/.agents/skills/$skill_name"
done

# Inspect startup without activating editor/plugin network bootstraps.
touch /root/.oh-my-zsh/oh-my-zsh.sh
zsh -c 'source /root/.zshrc; alias lb; alias ws' >/dev/null
if grep -Eq '\btv\b|task_name.*(file_finder|live_grep)' .config/zed/{tasks,keymap}.json; then
  fail 'Obsolete Television tasks remain'
fi
grep -q 'file_finder::Toggle' .config/zed/keymap.json
grep -q 'pane::DeploySearch' .config/zed/keymap.json

# Verify identities without creating commits or changing the user's identity.
mkdir -p /root/Documents/labs/sample /root/Documents/workspaces/sample /root/outside
for directory in /root/Documents/labs/sample /root/Documents/workspaces/sample /root/outside; do
  git -C "$directory" init -q
done
test "$(git -C /root/Documents/labs/sample config user.name)" = sgennrw
test "$(git -C /root/Documents/labs/sample -c user.name=sgennrw.ai config user.name)" = sgennrw.ai
test "$(git -C /root/Documents/labs/sample config user.name)" = sgennrw
expect_failure git -C /root/Documents/workspaces/sample var GIT_AUTHOR_IDENT
expect_failure git -C /root/outside var GIT_AUTHOR_IDENT

# Manual sync must reject non-interactive use, cancellation and credentials.
expect_failure bash sync.sh </dev/null
expect_failure run_sync q
expect_failure run_sync $'1\nno'
expect_failure run_sync $'1 1\nq'
expect_failure run_sync $'5\nq'
expect_failure run_sync $'\nq'
printf 'export TEST_API_KEY=value\n' > /root/.zshrc
expect_failure run_sync $'1\nsync'
cp zsh/.zshrc /root/.zshrc

# Individual and combined selections, including missing optional config files.
printf '\n# synced shell\n' >> /root/.zshrc
run_sync $'1\nsync'
grep -q 'synced shell' zsh/.zshrc
printf '\n# synced git\n' >> /root/.gitconfig
run_sync $'2\nsync'
grep -q 'synced git' .gitconfig
printf '// synced zed\n' >> /root/.config/zed/settings.json
rm /root/.config/lazygit/config.yml
run_sync $'3\nsync'
grep -q 'synced zed' .config/zed/settings.json
test -f .config/lazygit/config.yml
test "$(cat .config/zed/prompts/marker)" = 'old prompts'
test "$(cat .config/karabiner/automatic_backups/marker)" = 'old history'
test "$(cat .config/nvim/local.txt)" = 'unmanaged nvim file'
run_sync $'1 3\nsync'

# Only personal skills sync back; third-party skills and unrelated skills stay separate.
mkdir -p /root/.agents/skills/new-local /root/.agents/skills/git-skill \
  /dotfiles/agents/skills/new-local /dotfiles/agents/skills/git-skill
printf '# new local\n' > /root/.agents/skills/new-local/SKILL.md
printf 'gitdir: /elsewhere\n' > /root/.agents/skills/git-skill/.git
printf 'keep repository copy' > agents/skills/git-skill/marker
cp .agents/skills/find-skills/SKILL.md /tmp/vendor-before
printf 'machine-only edit' > /root/.agents/skills/find-skills/SKILL.md
touch /dotfiles/agents/skills/new-local/stale
run_sync $'4\nsync' > /tmp/sync-output
test -f agents/skills/new-local/SKILL.md
test ! -e agents/skills/new-local/stale
test "$(cat agents/skills/git-skill/marker)" = 'keep repository copy'
test ! -e agents/skills/unrelated
test ! -e agents/skills/find-skills
cmp .agents/skills/find-skills/SKILL.md /tmp/vendor-before
grep -q '?? agents/skills/new-local/' /tmp/sync-output
run_sync $'a\nsync'

# Missing personal skills are kept in the repository, not silently deleted.
mv /root/.agents/skills/new-local /root/saved-local
run_sync $'4\nsync'
test -f agents/skills/new-local/SKILL.md
mv /root/saved-local /root/.agents/skills/new-local

# Refuse ambiguous ownership before copying either skill with the same name.
mkdir -p agents/skills/find-skills
expect_failure bash -e -c 'DOTFILES_DIR=/dotfiles; source scripts/agents.sh'
rmdir agents/skills/find-skills

# A missing entire skills root is not a request to erase repository skills.
mv /root/.agents/skills /root/saved-skills
expect_failure run_sync $'4\nsync'
test -f agents/skills/new-local/SKILL.md
mv /root/saved-skills /root/.agents/skills

# A missing required source or symlink must fail before copying it.
mv /root/.zshrc /root/saved-zshrc
expect_failure run_sync $'1\nsync'
ln -s /root/saved-zshrc /root/.zshrc
expect_failure run_sync $'1\nsync'
rm /root/.zshrc
mv /root/saved-zshrc /root/.zshrc
mv /root/.config/zed /root/zed-target
ln -s /root/zed-target /root/.config/zed
expect_failure run_sync $'3\nsync'
expect_failure bash -e -c 'DOTFILES_DIR=/dotfiles; source scripts/shell.sh'
rm /root/.config/zed
mv /root/zed-target /root/.config/zed

# No commits are made by sync itself.
test "$(git rev-list --count HEAD)" -eq 1
printf 'PASS: install, backups, identities, manual sync, preservation and symlink boundaries\n'
