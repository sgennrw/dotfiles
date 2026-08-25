# Dotfiles — Agent Context

## Purpose
Dotfiles repo for setting up a new macBook. Single entrypoint `install.sh` automates everything; manual GUI steps documented in README.

## Repo Structure
```
install.sh                  # entrypoint: sources all scripts in order
sync.sh                     # copy live ~/.config/* and ~/.agents/skills/ back into repo
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
  neovim.sh                 # amix/vimrc + nvim init bridge
  docker.sh                 # ~/.docker/config.json for colima
  ssh.sh                    # generate per-identity ed25519 SSH keys + ~/.ssh/config
  agents.sh                 # restore skills from repo; clone superpowers
agents/
  .skill-lock.json          # tracks installed skills
  skills/                   # non-git skills (find-skills, tdd, etc.) — auto-synced
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
- `neovim.sh` idempotency guard checks for `runtimepath` (not `vim_runtime`) — matches actual written content
- `test.sh` uses `docker cp /root` (not `/root/.`) to preserve `.config/` path structure when extracting for inspection
- SSH keys: `~/.ssh/id_ed25519_labs` and `~/.ssh/id_ed25519_workspaces`; `~/.ssh/config` uses `Host github.com-labs` / `Host github.com-workspaces`
- `superpowers` is a git repo at `~/.agents/skills/superpowers` — NOT copied by sync; updated via `git pull`
- All other skills in `~/.agents/skills/` are plain directories — synced by `sync.sh` and restored by `agents.sh`; no names hardcoded (loop detects git repos by presence of `.git/`)

## Tools Installed (brew.sh)
Casks: iterm2, raycast, obsidian, zed, karabiner-elements, dbeaver-community, colemak-dh
Formulae: neovim, node, nvm, bat, git-delta, fzf, lazygit
Taps: jesseduffield/lazydocker/lazydocker
Also: docker, docker-compose, colima

## .zshrc Sections (in order)
1. oh-my-zsh (theme: avit, plugins: git, zsh-syntax-highlighting, zsh-autosuggestions, docker)
2. nvm
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
./sync.sh          # copies live files into repo, shows git diff
git diff           # review
git add -A && git commit -m "chore: sync dotfiles"
```
Syncs: `~/.zshrc`, `~/.gitconfig`, `~/.config/{karabiner,lazygit,nvim,zed}`, `~/.agents/.skill-lock.json`, all non-git skill dirs.

## Smoke-Test
```zsh
./test.sh
```
Checks: .zshrc copied, lb/ws aliases present, .gitconfig copied, nvim init.vim has runtimepath bridge, docker config.json has cliPluginsExtraDirs.

## Manual Steps (after install.sh)
iTerm2 only — see README.md ## iTerm2 Manual Setup
