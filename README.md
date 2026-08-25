# Dotfiles

The setup that works for me.

## Tools

- [Homebrew](https://brew.sh)
- [iTerm2](https://iterm2.com)
- [Neovim](https://neovim.io) with [amix/vimrc](https://github.com/amix/vimrc)
- [bat](https://github.com/sharkdp/bat) — cat with wings
- [delta](https://dandavison.github.io/delta/) — git diff
- [Raycast](https://www.raycast.com)
- [Obsidian](https://obsidian.md)
- [Zed](https://zed.dev)
- [Karabiner-Elements](https://karabiner-elements.pqrs.org)
- [DBeaver](https://dbeaver.io)
- [fzf](https://github.com/junegunn/fzf)
- [lazygit](https://github.com/jesseduffield/lazygit)
- [lazydocker](https://github.com/jesseduffield/lazydocker)
- [Colima](https://github.com/abiosoft/colima) — Docker daemon

## Quick Start

```zsh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
bash install.sh
```

The script automates everything it can. After it finishes, follow the
printed `[MANUAL]` instructions for iTerm2 profile import and preferences.

## Testing

Smoke-test that the install script runs cleanly (requires Docker):

```zsh
./test.sh
```
