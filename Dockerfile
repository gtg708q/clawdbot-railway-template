# Runtime image — openclaw installed directly from npm (always latest)
# cache-bust: 2026-03-17T22:08:32Z
FROM node:22-bookworm
ENV NODE_ENV=production

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    tini \
    python3 \
    python3-venv \
  && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@10.23.0 --activate

# Install openclaw globally to /usr/local (system default, available in PATH)
RUN npm install -g openclaw@latest

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
