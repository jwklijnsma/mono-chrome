# ── Build args ────────────────────────────────────────────────────────────────
ARG BUILD_VERSION=dev

# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM node:22-alpine AS builder

ARG BUILD_VERSION
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# ── Stage 2: Serve with nginx ─────────────────────────────────────────────────
FROM nginx:alpine

ARG BUILD_VERSION
LABEL org.opencontainers.image.title="monochrome" \
      org.opencontainers.image.description="Open-source privacy-respecting ad-free TIDAL web UI" \
      org.opencontainers.image.source="https://github.com/monochrome-music/monochrome" \
      org.opencontainers.image.version="${BUILD_VERSION}"

COPY --from=builder /app/dist /usr/share/nginx/html

# SPA fallback: all routes → index.html
RUN printf 'server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1
