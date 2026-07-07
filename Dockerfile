# syntax=docker/dockerfile:1
# Serves the pre-built Flutter web bundle (build/web) via a tiny nginx — per CC_LIVE_STACK §2
# ("serve their built output ... don't over-build"). Build the bundle first with
# `flutter build web --release` (build/ is gitignored). Enabled via `docker compose --profile courier`.
FROM nginx:1.27-alpine AS runtime
COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=5s --retries=6 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1
