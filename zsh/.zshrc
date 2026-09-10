# --- Homebrew ---
# Login shells do not always inherit Homebrew's PATH (notably on Apple Silicon).
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- oh-my-zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="avit"

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  docker
)

source $ZSH/oh-my-zsh.sh

# --- node: n ---
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"

# --- python: pyenv ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# --- pnpm ---
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# --- bun ---
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- rust/cargo ---
[ -s "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

# --- fzf ---
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --no-height"

# --- aliases: navigation ---
alias lb='function _lb() { cd "$HOME/Documents/labs/$1" || return; }; _lb'
alias ws='function _ws() { cd "$HOME/Documents/workspaces/$1" || return; }; _ws'

# --- aliases: tools ---
alias zd='lazydocker'
alias zg='lazygit'
alias p='pnpm'

# --- aliases: docker-compose ---
alias dco='docker-compose'
alias dcb='docker-compose build'
alias dce='docker-compose exec'
alias dcps='docker-compose ps'
alias dcrestart='docker-compose restart'
alias dcrm='docker-compose rm'
alias dcr='docker-compose run'
alias dcstop='docker-compose stop'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dcl='docker-compose logs'
alias dclf='docker-compose logs -f'
