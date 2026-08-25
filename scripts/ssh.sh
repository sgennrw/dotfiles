#!/usr/bin/env bash

printf "\n\033[1m=== SSH KEYS ===\033[0m\n"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

ensure_key() {
  local key_path="$1"
  local comment="$2"

  if [ ! -f "$key_path" ]; then
    printf "Generating %s SSH key...\n" "$comment"
    ssh-keygen -t ed25519 -C "$comment" -f "$key_path" -N ""
  elif [ ! -f "$key_path.pub" ]; then
    printf "Recreating missing %s public key...\n" "$comment"
    ssh-keygen -y -f "$key_path" > "$key_path.pub"
    chmod 644 "$key_path.pub"
  else
    printf "  [skip] %s key already exists\n" "$comment"
  fi
}

# --- labs ---
ensure_key "$HOME/.ssh/id_ed25519_labs" "sgennrw (labs)"

# --- workspaces ---
ensure_key "$HOME/.ssh/id_ed25519_workspaces" "workspaces"

# --- ~/.ssh/config ---
printf "\n\033[1m=== SSH CONFIG ===\033[0m\n"
SSH_CONFIG="$HOME/.ssh/config"

if ! grep -q '^Host github.com-labs$' "$SSH_CONFIG" 2>/dev/null; then
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

if ! grep -q '^Host github.com-workspaces$' "$SSH_CONFIG" 2>/dev/null; then
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
