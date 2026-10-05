#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_PORT="${WEB_PORT:-4174}"
API_URL="${API_URL:-http://localhost:8080}"
export WEB_PORT
export WEB_URL="http://127.0.0.1:${WEB_PORT}"
export INSTALL_PROMPT_DIR="${INSTALL_PROMPT_DIR:-/opt/cursor/artifacts/install-prompt}"

echo "==> Starting backend on ${API_URL}"
cd "${ROOT}/backend"
./mvnw -q spring-boot:run -Dspring-boot.run.profiles=dev &
BACKEND_PID=$!
trap 'kill "${BACKEND_PID}" 2>/dev/null || true' EXIT

for _ in $(seq 1 60); do
  if curl -sf "${API_URL}/actuator/health" >/dev/null; then
    break
  fi
  sleep 2
done
curl -sf "${API_URL}/actuator/health" >/dev/null

echo "==> Building Flutter web (install prompt screenshots)"
cd "${ROOT}/mobile"
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL="${API_URL}" \
  --dart-define=ENABLE_SEMANTICS=true \
  --dart-define=FORCE_INSTALL_PROMPT=true

echo "==> Serving web"
npx --yes serve -s build/web -l "${WEB_PORT}" &
SERVE_PID=$!
trap 'kill "${SERVE_PID}" "${BACKEND_PID}" 2>/dev/null || true' EXIT

for _ in $(seq 1 30); do
  if curl -sf "${WEB_URL}/" >/dev/null; then
    break
  fi
  sleep 1
done
curl -sf "${WEB_URL}/" >/dev/null

echo "==> Playwright install-prompt screenshots"
cd "${ROOT}/e2e"
npm ci
npx playwright install webkit
npx playwright install-deps webkit
npx playwright test -c playwright.install-prompt.config.ts

echo "Screenshots in ${INSTALL_PROMPT_DIR}"
