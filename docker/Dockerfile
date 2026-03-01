FROM node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gh \
        unzip \
        tini \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://bun.sh/install | bash \
    && install -m 755 /root/.bun/bin/bun /usr/local/bin/bun \
    && ln -sf /usr/local/bin/bun /usr/local/bin/bunx \
    && rm -rf /root/.bun

RUN npm install -g opencode-ai @grinev/opencode-telegram-bot

RUN useradd --create-home --uid 10001 --shell /bin/bash opencode

COPY docker/opencode-entrypoint.sh /usr/local/bin/opencode-entrypoint.sh
COPY docker/telegram-bot-entrypoint.sh /usr/local/bin/telegram-bot-entrypoint.sh
COPY docker/all-in-one-entrypoint.sh /usr/local/bin/all-in-one-entrypoint.sh
COPY docker/github-app-token.mjs /usr/local/bin/github-app-token.mjs
COPY docker/gh-wrapper.sh /usr/local/bin/gh

RUN chmod +x /usr/local/bin/opencode-entrypoint.sh /usr/local/bin/telegram-bot-entrypoint.sh /usr/local/bin/all-in-one-entrypoint.sh /usr/local/bin/github-app-token.mjs /usr/local/bin/gh

USER opencode
ENV HOME=/home/opencode
WORKDIR /workspace
VOLUME ["/workspace", "/home/opencode"]

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/all-in-one-entrypoint.sh"]
