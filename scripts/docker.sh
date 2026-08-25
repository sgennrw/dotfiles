#!/usr/bin/env bash

printf "\n\033[1m=== DOCKER / COLIMA ===\033[0m\n"

DOCKER_CONFIG="$HOME/.docker/config.json"
mkdir -p "$HOME/.docker"

# Detect Homebrew prefix (Apple Silicon vs Intel)
if [ -d "/opt/homebrew" ]; then
  HOMEBREW_PREFIX="/opt/homebrew"
else
  HOMEBREW_PREFIX="/usr/local"
fi

PLUGIN_DIR="$HOMEBREW_PREFIX/lib/docker/cli-plugins"

if [ ! -f "$DOCKER_CONFIG" ]; then
  printf "Writing ~/.docker/config.json...\n"
  cat > "$DOCKER_CONFIG" <<EOF
{
  "cliPluginsExtraDirs": [
    "$PLUGIN_DIR"
  ]
}
EOF
elif ! grep -q "cliPluginsExtraDirs" "$DOCKER_CONFIG"; then
  printf "Patching cliPluginsExtraDirs into existing ~/.docker/config.json...\n"
  python3 - "$DOCKER_CONFIG" "$PLUGIN_DIR" <<'PYEOF'
import json, sys
path, plugin_dir = sys.argv[1], sys.argv[2]
with open(path) as f:
    cfg = json.load(f)
cfg.setdefault("cliPluginsExtraDirs", [])
if plugin_dir not in cfg["cliPluginsExtraDirs"]:
    cfg["cliPluginsExtraDirs"].append(plugin_dir)
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PYEOF
else
  printf "  [skip] cliPluginsExtraDirs already set in ~/.docker/config.json\n"
fi

printf "\n[MANUAL] Start Docker daemon:\n"
printf "  colima start\n"
