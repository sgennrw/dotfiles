#!/usr/bin/env bash

printf "\n\033[1m=== SSH KEYS ===\033[0m\n"

# --- labs ---
if [ ! -f "$HOME/.ssh/id_ed25519_labs" ]; then
  printf "Generating labs SSH key...\n"
  ssh-keygen -t ed25519 -C "sgennrw (labs)" -f "$HOME/.ssh/id_ed25519_labs" -N ""
else
  printf "  [skip] ~/.ssh/id_ed25519_labs already exists\n"
fi

# --- workspaces ---
if [ ! -f "$HOME/.ssh/id_ed25519_workspaces" ]; then
  printf "Generating workspaces SSH key...\n"
  ssh-keygen -t ed25519 -C "workspaces" -f "$HOME/.ssh/id_ed25519_workspaces" -N ""
else
  printf "  [skip] ~/.ssh/id_ed25519_workspaces already exists\n"
fi

# --- ~/.ssh/config ---
printf "\n\033[1m=== SSH CONFIG ===\033[0m\n"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

SSH_CONFIG="$HOME/.ssh/config"

if ! grep -q "id_ed25519_labs" "$SSH_CONFIG" 2>/dev/null; then
  cat >> "$SSH_CONFIG" <<'EOF'

# labs (sgennrw)
Host github.com-labs
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_labs
  IdentitiesOnly yes
EOF
  printf "  [added] github.com-labs block\n"
else
  printf "  [skip] github.com-labs already in ~/.ssh/config\n"
fi

if ! grep -q "id_ed25519_workspaces" "$SSH_CONFIG" 2>/dev/null; then
  cat >> "$SSH_CONFIG" <<'EOF'

# workspaces (company account)
Host github.com-workspaces
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_workspaces
  IdentitiesOnly yes
EOF
  printf "  [added] github.com-workspaces block\n"
else
  printf "  [skip] github.com-workspaces already in ~/.ssh/config\n"
fi

chmod 600 "$SSH_CONFIG"

# --- print public keys to add to GitHub ---
printf "\n\033[1m=== ADD TO GITHUB ===\033[0m\n"
printf "\n[labs] https://github.com/settings/keys\n"
cat "$HOME/.ssh/id_ed25519_labs.pub"
printf "\n[workspaces] add to company GitHub account\n"
cat "$HOME/.ssh/id_ed25519_workspaces.pub"
