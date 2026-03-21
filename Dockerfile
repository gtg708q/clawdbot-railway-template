# Runtime image — openclaw installed directly from npm (always latest)
# cache-bust: 2026-03-17T22:27:54Z
FROM node:22-bookworm
ENV NODE_ENV=production

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    tini \
    python3 \
    python3-venv \
    curl \
    gpg \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@10.23.0 --activate

# Install openclaw globally to /usr/local
RUN npm install -g openclaw@latest

# Tell the wrapper where to find the openclaw entry point
ENV OPENCLAW_ENTRY=/usr/local/lib/node_modules/openclaw/dist/entry.js
ENV OPENCLAW_NODE=node

# At runtime, redirect user npm installs to the persistent volume
ENV NPM_CONFIG_PREFIX=/data/npm
ENV NPM_CONFIG_CACHE=/data/npm-cache
ENV PNPM_HOME=/data/pnpm
ENV PNPM_STORE_DIR=/data/pnpm-store
ENV PATH="/data/npm/bin:/data/pnpm:/usr/local/bin:${PATH}"

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force

COPY src ./src

EXPOSE 8080

ENTRYPOINT ["tini", "--"]
CMD ["node", "src/server.js"]
