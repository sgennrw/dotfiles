FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

RUN apt-get update && apt-get install -y \
    bash \
    zsh \
    git \
    curl \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# Stub: brew — exits 1 for list (not installed), 0 for everything else
RUN cat > /usr/local/bin/brew <<'EOF'
#!/usr/bin/env bash
case "$*" in
  "list --cask "*|"list "*) exit 1 ;;
  *) exit 0 ;;
esac
EOF
RUN chmod +x /usr/local/bin/brew

# Stub: pre-create ohmyzsh so the "already installed" branch fires
RUN mkdir -p /root/.oh-my-zsh/custom/plugins

# Stub: pre-create vim_runtime so the "already installed" branch fires
RUN mkdir -p /root/.vim_runtime && touch /root/.vim_runtime/.keep

# Stub: git — intercepts clone (creates dest dir), passes everything else through
RUN cat > /usr/local/bin/git <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "clone" ]; then
  mkdir -p "${@: -1}"
  exit 0
fi
exec /usr/bin/git "$@"
EOF
RUN chmod +x /usr/local/bin/git

COPY . /dotfiles
WORKDIR /dotfiles

RUN chmod +x install.sh scripts/brew.sh scripts/shell.sh

CMD ["bash", "install.sh"]
