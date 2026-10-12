#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_PORT="${WEB_PORT:-4175}"
API_URL="${API_URL:-http://localhost:8080}"
ENABLE_SEMANTICS="${ENABLE_SEMANTICS:-true}"
CHIP_SCREENSHOT_SUFFIX="${CHIP_SCREENSHOT_SUFFIX:-after}"
export WEB_PORT
export WEB_URL="http://127.0.0.1:${WEB_PORT}"
export CATEGORY_CHIPS_DIR="${CATEGORY_CHIPS_DIR:-${ROOT}/artifacts/screenshots}"
export CHIP_SCREENSHOT_SUFFIX

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

echo "==> Building Flutter web (ENABLE_SEMANTICS=${ENABLE_SEMANTICS})"
cd "${ROOT}/mobile"
flutter pub get
SEMANTICS_FLAG=()
if [[ "${ENABLE_SEMANTICS}" == "true" ]]; then
  SEMANTICS_FLAG=(--dart-define=ENABLE_SEMANTICS=true)
fi
flutter build web --release \
  --dart-define=API_BASE_URL="${API_URL}" \
  "${SEMANTICS_FLAG[@]}" \
  --dart-define=DISABLE_INSTALL_PROMPT=true

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

echo "==> Playwright category chip screenshots"
cd "${ROOT}/e2e"
npm ci
npx playwright install webkit
npx playwright install-deps webkit
npx playwright test category-chips-screenshot.spec.ts -c playwright.category-chips.config.ts

echo "Screenshots in ${CATEGORY_CHIPS_DIR}"
