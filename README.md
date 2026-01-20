# Dotfiles

🔧 The setup that works for me

## Tools

- homebrew
- iterm2
- vscode
- nvm
- neovim with [amix/vimrc](https://github.com/amix/vimrc)
- [bat](https://github.com/sharkdp/bat) ; a cat with wing
- [delta](https://dandavison.github.io/delta/) ; `git diff`

## Steps

### Install `Homebrew`

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

### Setup `ITerm2`

```zsh
brew install --cask iterm2
```

1. Setup `ohmyzsh`

   1. Install `ohmyzsh`

   ```zsh
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

   2. Install zsh-autosuggestions & zsh-syntax-highlighting

   ```zsh
   git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
   ```

   3. Copy `./scritp` into `~/script`
   4. Replace `~/.zshrc` with `./iterm2/.zshrc`

2. Import Profile

   1. Go to `Preferences > Profiles`
   2. On the sidebar menu, click `Other Actions` > `Import Json Profiles`
   3. Import `./iterm2/iterm2-profile.json`
   4. Remove old default

3. Setup Preferences
   1. Go to `Preferences > Appearance > General`
      > **Theme:** Minimal  
      > **Tab bar localtion:** Top  
      > **Status bar location:** Bottom
   2. Go to `Preferences > Appearance > Tabs`
      > [x] Show tab bar even when there is only one tab
   3. Go to `Preferences > Keys > Hotkey`
      > [x] Show/hide all windows with a system-wide hotkey
      >
      > > **Hotkey:** `⌥Space`

### Setup `VSCode`

```zsh
brew install --cask visual-studio-code
```

1. Install [Setting Sync](https://marketplace.visualstudio.com/items?itemName=Shan.code-settings-sync) plugin
   > 1. **Upload Key:** Shift + Option + U
   > 2. **Download Key:** Shift + Option + D

### Setup `Neovim`

```zsh
brew install neovim
```

1. Install Ultimate [vimrc](https://github.com/amix/vimrc)

```zsh
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
```

2. Share the config file to neovim

Add below content to `~/.config/nvim/init.vim`
```zsh
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
```

## Install docker [colima](https://github.com/abiosoft/colima)
```zsh
brew install docker docker-compose colima
```
Note that
```
Compose is a Docker plugin. For Docker to find the plugin, add "cliPluginsExtraDirs" to ~/.docker/config.json:
  "cliPluginsExtraDirs": [
      "/opt/homebrew/lib/docker/cli-plugins"
  ]
```
Then will be able to start docker daemon by
```zsh
colima start
```

## Install other tools

```zsh
brew install node
brew install nvm
brew install bat
brew install git-delta
brew install --cask raycast
brew install --cask obsidian
brew install --cask zed
brew install --cask karabiner-elements
brew install --cask dbeaver-community
brew install borders
brew install fzf
brew install jesseduffield/lazydocker/lazydocker
brew install lazygit
brew install television
```
