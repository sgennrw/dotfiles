# Dotfiles — Agent Context

## Purpose

Dotfiles repo for setting up a new MacBook. Single entrypoint `install.sh` automates setup; account configuration, Docker startup, and manual GUI steps are documented in README.

## Agent Safety

- `sync.sh` is a manual workflow: the user must review `git diff` before deciding whether to commit.
- Review untracked files shown by `git status --short` too. Never run the Docker-only fixture scripts against the host.

## Repo Structure

```
install.sh                  # entrypoint: sources all scripts in order
sync.sh                     # copy selected managed configuration and local skills into repo
test.sh                     # Docker smoke-test (Ubuntu 22.04)
Dockerfile                  # smoke-test image with stubbed brew/git/ohmyzsh
zsh/
  .zshrc                    # mirrors ~/.zshrc
.gitconfig                  # global git config; uses includeIf per folder
.config/
  labs.gitconfig            # git user for ~/Documents/labs/
  workspaces.gitconfig      # git user for ~/Documents/workspaces/ (fill in later)
  karabiner/
  lazygit/
  nvim/
  zed/
scripts/
  brew.sh                   # homebrew + all packages
  shell.sh                  # ohmyzsh, plugins, file copies
  ssh.sh                    # generate per-identity ed25519 SSH keys + ~/.ssh/config
  agents.sh                 # restore skills from repo; clone superpowers
  lib.sh                    # safe transfers, symlink rejection, installer backups
tests/                      # bootstrap and install/sync regression checks
agents/
  skills/                   # personal skills
.agents/skills/             # downloaded third-party skills, Git-ignored
skills-lock.json            # project lock maintained by the Skills CLI
iterm2/
  iterm2-profile.json       # imported manually (see README)
```

## Key Decisions

- `Scripts/` directory removed — `util.sh` was unused; `lb`/`ws` inlined as aliases in `.zshrc`
- VS Code removed from toolset
- `.zshrc` lives at `zsh/.zshrc` (mirrors macOS `~/.zshrc`)
- Git identity is per-directory via `includeIf` in `.gitconfig`:
  - `~/Documents/labs/` → `~/.config/labs.gitconfig` (sgennrw / nt.salisa@gmail.com)
  - `~/Documents/workspaces/` → `~/.config/workspaces.gitconfig` (company account, TBD)
  - `useconfigonly = true` blocks commits outside these dirs without explicit identity
- `init.lua` is the canonical Neovim entrypoint; no generated `init.vim` bridge is installed
- `.config` transfers use Git's ignore rules; exclude unwanted files in `.gitignore`. New non-ignored files are picked up automatically, Git metadata is always skipped, and files absent from the source remain untouched at the destination.
- Managed transfer boundaries reject symlinks. Installation backs up existing settings under a unique `~/.local/state/dotfiles-backups/install-<timestamp>-<suffix>/`, preserving home-relative paths; restore individual files manually after reviewing them.
- Homebrew is resolved from PATH, `/opt/homebrew/bin/brew`, then `/usr/local/bin/brew`, and `shellenv` is initialized before packages and in new shells.
- Node uses `n` only. Zed uses native search/file finding; there are no Television tasks.
- `test.sh` uses `docker cp /root` (not `/root/.`) to preserve `.config/` path structure when extracting for inspection
- SSH keys: `~/.ssh/id_ed25519_labs` and `~/.ssh/id_ed25519_workspaces`; `~/.ssh/config` uses `Host github.com-labs` / `Host github.com-workspaces`
- `superpowers` is a git repo at `~/.agents/skills/superpowers` — NOT copied by sync; updated via `git pull`
- Add third-party skills from this repo with `npx skills install <source> --skill <name> --agent codex --yes` (no `--global`). Commit only the CLI-generated `skills-lock.json`; `.agents/skills/` is ignored. Keep personal skills in `agents/skills/`, with distinct names.
- `agents.sh` first restores the project lock inside this repo using `npx --yes skills@1.5.23 experimental_install`, verifies downloaded skills exist, then copies both skill folders into `~/.agents/skills/`. Restoration needs network access and does not guarantee historical versions from hashes. The machine's global lock is untouched. `sync.sh` only copies back personal skills already present under `agents/skills/`. Missing personal skills and unrelated machine skills are preserved. Git repos are detected by a `.git` directory or file and skipped by sync and skill replacement.

## Tools Installed (brew.sh)

Casks: iterm2, raycast, obsidian, zed, karabiner-elements, dbeaver-community, colemak-dh
Formulae: neovim, node, bat, ripgrep, git-delta, fzf, lazygit, pyenv, pnpm, bun, n, rust
Taps: jesseduffield/lazydocker/lazydocker
Also: docker, docker-compose, colima

## .zshrc Sections (in order)

1. Homebrew shellenv
2. oh-my-zsh (theme: avit, plugins: git, zsh-syntax-highlighting, zsh-autosuggestions, docker)
3. n (N_PREFIX=$HOME/.n)
4. pyenv
5. pnpm
6. bun
7. rust/cargo ($HOME/.local/bin/env)
8. fzf + FZF_CTRL_T_OPTS (bat preview)
9. Navigation aliases: lb (labs), ws (workspaces)
10. Tool aliases: zd (lazydocker), zg (lazygit), p (pnpm)
11. docker-compose aliases: dco dcb dce dcps dcrestart dcrm dcr dcstop dcu dcd dcl dclf

## Sync Workflow

```zsh
./sync.sh          # select one or more groups, then review the diff
git diff           # review
git status --short # inspect untracked files too
git add -A && git commit -m "chore: sync dotfiles"
```

Selections: `1` `~/.zshrc`, `2` `~/.gitconfig`, `3` non-ignored `~/.config` files, `4` personal skills in `agents/skills/`, or `a` for all. Group 4 requires rsync and preserves missing personal skills. Third-party and Git-managed skills are excluded from mirroring.

## Smoke-Test

```zsh
./test.sh
```

Checks cover project-lock restoration from an empty downloaded-skills directory, restore failures, copying both skill folders, personal-only skill sync, Homebrew discovery, repeat installation/backups, preserved runtime data/keys, Git identities, and interactive sync behavior. The disposable Ubuntu container uses Node and mocks the Skills CLI, external package installation, and Git clones. Containers and images are unique per run and cleaned up. This does not verify actual macOS installation or editor startup.

## Manual Steps (after install.sh)

See README's After Installation and iTerm2 Manual Setup sections: fill in the workspace Git identity, register each SSH public key with its GitHub account and use host-alias remotes, run `colima start` and `docker info`, import iTerm2 settings, and check tool versions and both editors on a fresh Mac.
