# Dotfiles

The setup that works for me.

## Tools

- [Homebrew](https://brew.sh)
- [iTerm2](https://iterm2.com)
- [Neovim](https://neovim.io) with the checked-in Lua configuration
- [bat](https://github.com/sharkdp/bat) — cat with wings
- [delta](https://dandavison.github.io/delta/) — git diff
- [Raycast](https://www.raycast.com)
- [Obsidian](https://obsidian.md)
- [Zed](https://zed.dev)
- [Karabiner-Elements](https://karabiner-elements.pqrs.org)
- [DBeaver](https://dbeaver.io)
- [fzf](https://github.com/junegunn/fzf)
- [ripgrep](https://github.com/BurntSushi/ripgrep) — search for editor integrations
- [n](https://github.com/tj/n) — Node version manager (`N_PREFIX=$HOME/.n`)
- [lazygit](https://github.com/jesseduffield/lazygit)
- [lazydocker](https://github.com/jesseduffield/lazydocker)
- [Colima](https://github.com/abiosoft/colima) — Docker daemon

## Quick Start

```zsh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
bash install.sh
```

Homebrew is discovered from PATH or its standard Apple Silicon/Intel locations and initialized before package installation. New shells initialize it too. Node uses `n`; nvm is not configured. Zed uses its native file finder and search, with no Television dependency.

After installation, restart your terminal and complete the account, Docker, and iTerm2 steps below.

## Managed Configuration and Backups

Installation and sync copy `.config` files except those excluded by Git's ignore rules. `.gitignore` is the place to exclude unwanted configuration or application data; new non-ignored files are picked up automatically.

Ignored application data, including Zed databases and Karabiner automatic backups, is not copied or deleted. Git metadata is always skipped. Paths containing symlinks are rejected. Files absent from the source are left untouched at the destination.

Before replacing existing managed settings, installation saves copies in a unique `~/.local/state/dotfiles-backups/install-<timestamp>-<suffix>/` directory and prints its location. Backup paths mirror your home directory. To restore a setting, close the relevant application, inspect the backup, and copy that individual file back. For example, replace the placeholder with the printed directory:

```zsh
cp "$HOME/.local/state/dotfiles-backups/install-<timestamp>-<suffix>/.zshrc" ~/.zshrc
```

Do not paste the placeholder literally. Restore other files the same way, then reopen the application. Installation preserves unmanaged files and existing SSH keys.

## After Installation

1. Set your company identity in `~/.config/workspaces.gitconfig`, replacing the placeholders with your own values:

   ```zsh
   git config --file ~/.config/workspaces.gitconfig user.name "Your Name"
   git config --file ~/.config/workspaces.gitconfig user.email "you@company.example"
   ```

   Labs repositories belong under `~/Documents/labs/`; company repositories belong under `~/Documents/workspaces/`. Git refuses commits without an explicit identity outside these directories, and in workspaces until configured. Check the effective identity from within a repository with `git var GIT_AUTHOR_IDENT`.

2. Register `~/.ssh/id_ed25519_labs.pub` and `~/.ssh/id_ed25519_workspaces.pub` with their respective GitHub accounts. Keep the private keys local. Use the matching SSH host alias when cloning or setting a remote:

   ```zsh
   git clone git@github.com-labs:OWNER/REPOSITORY.git ~/Documents/labs/REPOSITORY
   git remote set-url origin git@github.com-workspaces:COMPANY/REPOSITORY.git
   ssh -T git@github.com-labs
   ssh -T git@github.com-workspaces
   ```

   Run `set-url` inside the relevant company repository. Successful GitHub authentication prints the account name; GitHub does not provide shell access.

3. Start the Docker runtime and verify the daemon:

   ```zsh
   colima start
   docker info
   ```

4. Import the iTerm2 profile below. Open Neovim and Zed on the Mac, allow their initial plugin/tool setup to finish, and check file finding and project search. Check `brew --version`, `node --version`, and `rg --version` in a new terminal. These real-machine checks are separate from the Docker smoke suite.

## iTerm2 Manual Setup

**Profile Import:**

1. Open iTerm2
2. Go to `Preferences > Profiles`
3. On the sidebar, click `Other Actions` > `Import JSON Profiles`
4. Select `iterm2/iterm2-profile.json` from this repo
5. Remove the old Default profile

**Preferences:**

- `Preferences > Appearance > General`
  - Theme: `Minimal` | Tab bar: `Top` | Status bar: `Bottom`
- `Preferences > Appearance > Tabs`
  - `[x]` Show tab bar even when there is only one tab
- `Preferences > Keys > Hotkey`
  - `[x]` Show/hide all windows with system-wide hotkey — `⌥Space`

## Testing

Run the isolated Ubuntu Docker suite (requires a running Docker daemon):

```zsh
./test.sh
```

The suite mocks Homebrew packages, downloads, Git clones, and the Skills CLI. It starts without downloaded skills and checks restoration from the project lock, copying both skill folders, Homebrew discovery, repeat installation, backups, preserved runtime data/keys, Git identity, and interactive sync behavior. Each run owns its container and image and removes them afterward.

Passing this suite does not verify actual macOS package installation, remote skill availability, or editor startup. Complete the fresh-Mac checks above.

## Agent Skills

Keep personal skills separate from CLI-installed skills:

```text
agents/skills/    Your own skills
.agents/skills/   Downloaded third-party skills (Git-ignored)
skills-lock.json Project lock managed by the Skills CLI
```

Run the CLI from this repository, without `--global`:

```zsh
npx skills install vercel-labs/skills --skill find-skills --agent codex --yes
npx skills install mattpocock/skills --skill tdd improve-codebase-architecture grill-with-docs code-review --agent codex --yes
```

The `--agent codex` option selects the `.agents/skills/` project folder. Commit only `skills-lock.json` for third-party skills; downloaded files are ignored. Create and commit your own skills in `agents/skills/<name>/SKILL.md`; use distinct names across the two folders.

`install.sh` first runs `npx --yes skills@1.5.23 experimental_install` inside this repo to restore `skills-lock.json`, then copies downloaded and personal skills to `~/.agents/skills/`, with backups. The native restore command needs network access; it does not restore exact historical versions from the recorded hashes. The machine's global skill lock is left untouched. Update third-party skills in this repository with `npx skills update --project --yes` and commit the updated lock. Unrelated machine skills and Git-managed skills are preserved; Superpowers remains a separate Git clone.

## Updating Superpowers

Superpowers is a git repo and is not touched by `sync.sh`. Update it manually:

```zsh
git -C ~/.agents/skills/superpowers pull
```

## AI-Authored Commits

Within `~/Documents/labs/`, normal commits use the default labs identity: `sgennrw <nt.salisa@gmail.com>`.

For a commit authored by AI, override only the name for that one commit:

```zsh
git -c user.name=sgennrw.ai commit -m "your message"
```

Later commits continue to use `sgennrw`; the labs email address is unchanged.

## Sync Workflow

Run `./sync.sh` from an interactive terminal. Select one or more groups by number:

- `1` — `~/.zshrc`
- `2` — `~/.gitconfig`
- `3` — `~/.config` files, excluding Git-ignored paths
- `4` — your own skills already listed as folders under `agents/skills/`
- `a` — all groups

For example, enter `1 3` to sync the shell config and non-ignored `.config` files, then type `sync` to confirm. Group `4` uses rsync to copy your personal skills back from the machine. Missing skills are kept in the repository. Third-party skills, unrelated machine skills, and Git repositories are skipped.

The summary includes untracked files as well as tracked changes. Review `git diff` and inspect newly added files shown by `git status --short` before deciding whether to commit. Sync never commits automatically.

```zsh
git diff
git status --short
git add -A && git commit -m "chore: sync dotfiles"
```
