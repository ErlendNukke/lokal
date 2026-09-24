#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_PORT="${WEB_PORT:-4173}"
API_URL="${API_URL:-http://localhost:8080}"
export WEB_PORT
export WEB_URL="http://127.0.0.1:${WEB_PORT}"
export WALKTHROUGH_DIR="${WALKTHROUGH_DIR:-/opt/cursor/artifacts/walkthrough}"

echo "==> Expecting API at ${API_URL}"
if ! curl -sf "${API_URL}/actuator/health" >/dev/null; then
  echo "Start the backend first, e.g.:"
  echo "  cd backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev"
  exit 1
fi

echo "==> Building Flutter web (release + semantics)"
cd "${ROOT}/mobile"
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL="${API_URL}" \
  --dart-define=ENABLE_SEMANTICS=true

echo "==> Serving web on ${WEB_URL}"
if command -v npx >/dev/null; then
  npx --yes serve -s build/web -l "${WEB_PORT}" &
else
  python3 -m http.server "${WEB_PORT}" --directory build/web &
fi
SERVE_PID=$!
trap 'kill "${SERVE_PID}" 2>/dev/null || true' EXIT

sleep 2

echo "==> Running Playwright walkthrough (WebKit / iPhone 14)"
cd "${ROOT}/e2e"
npm install
npx playwright install webkit
npm run test:walkthrough

echo "Screenshots: ${WALKTHROUGH_DIR}"
