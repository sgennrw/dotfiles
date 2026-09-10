FROM node:22-bullseye-slim AS node-runtime
FROM ubuntu:22.04

COPY --from=node-runtime /usr/local/bin/node /usr/local/bin/node

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV DOTFILES_TEST_CONTAINER=1

RUN apt-get update && apt-get install -y \
    bash \
    zsh \
    git \
    curl \
    rsync \
    openssh-client \
    util-linux \
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

# Stub: git — intercepts clone (creates dest dir), passes everything else through
RUN cat > /usr/local/bin/git <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "clone" ]; then
  mkdir -p "${@: -1}"
  mkdir -p "${@: -1}/.git"
  exit 0
fi
exec /usr/bin/git "$@"
EOF
RUN chmod +x /usr/local/bin/git

# Stub the project-lock restore, not the subsequent copy to the machine.
RUN cat > /usr/local/bin/npx <<'EOF'
#!/usr/local/bin/node
const fs = require('fs');
const assert = require('assert');
assert.deepStrictEqual(process.argv.slice(2), ['--yes', 'skills@1.5.23', 'experimental_install']);
const lock = JSON.parse(fs.readFileSync('skills-lock.json'));
if (process.env.SKILLS_STUB_FAIL) process.exit(1);
if (!process.env.SKILLS_STUB_SKIP) {
  for (const name of Object.keys(lock.skills)) {
    fs.mkdirSync(`.agents/skills/${name}`, { recursive: true });
    fs.writeFileSync(`.agents/skills/${name}/SKILL.md`, `# ${name}\n`);
  }
}
EOF
RUN chmod +x /usr/local/bin/npx

COPY . /dotfiles
WORKDIR /dotfiles

# Config transfers use Git's ignore matching; host Git metadata is excluded.
RUN git init -q

RUN chmod +x install.sh scripts/brew.sh scripts/shell.sh

CMD ["bash", "install.sh"]
