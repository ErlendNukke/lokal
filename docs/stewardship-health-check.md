# Stewardship health check (2026-09-21)

First-pass inventory of **ErlendNukke/lokal** — Flutter + Spring Boot marketplace MVP.

## Architecture snapshot

| Layer | Status | Notes |
|-------|--------|-------|
| **Flutter app** (`mobile/`) | Implemented | Browse map, auth, orders, producer dashboard, profile |
| **Spring Boot API** (`backend/`) | Implemented | JWT auth, products, orders, reviews, image upload |
| **PostgreSQL / H2** | Implemented | Liquibase migrations; H2 dev, Postgres prod (Neon) |
| **S3 / R2 images** | Implemented | `S3StorageService` + `ImageOptimizer`; local fs for dev |
| **Deploy** | Live | API on Render, web on Firebase (`lokal-eu.web.app`) |

## Production smoke (verified 2026-09-21)

| Check | Result |
|-------|--------|
| `GET /actuator/health` | `UP` |
| `POST /api/auth/login` (anna@lokal.app) | 200 + JWT |
| `GET /api/products?lat=59.437&lng=24.7536` | 200 + product list |
| `POST /api/orders` (buyer) | 201-style 200, order created |
| CORS preflight from `https://lokal-eu.web.app` | `Access-Control-Allow-Origin` set |
| BOTH-role user (mari@lokal.app) can order | Works (not blocked) |

## Backend tests

```
mvn test — 9 tests, 0 failures (requires JDK 25; Docker image uses eclipse-temurin:25)
```

Coverage is thin (storage, image optimizer, S3 path-style, exception handler) — no integration/API tests.

## What's implemented vs stubbed

**Implemented end-to-end**

- Email register/login, JWT persistence in Flutter (`SharedPreferences`)
- Browse: OSM map, 10 km radius, category filter, search
- Product detail + order (pickup/delivery)
- Producer CRUD + photo upload (HEIC→JPEG on web via canvas; native via `ImagePicker`)
- Order lifecycle: accept / reject / complete / cancel + reviews
- Profile update (name, role, farm settings)

**Stubbed / MVP shortcuts**

- Google login: demo token only, no real ID-token verification (`AuthService.googleLogin`)
- Notifications: none (orders visible in list only)
- Payments: none (cash/pickup model)
- Geo: Haversine in Java, not PostGIS

## Open TODOs in repo

Only Android template TODOs (`mobile/android/app/build.gradle.kts` — application ID / release signing). No backend/mobile feature TODOs found.

## Deploy config notes

| File | Purpose |
|------|---------|
| `render.yaml` | Render Docker web service, health check `/actuator/health`, env vars for DB/JWT/S3 |
| `docker-compose.yml` | Local Postgres + MinIO; API under `full` profile |
| `firebase.json` (root + `mobile/`) | Hosting; root uses `mobile/build/web`, mobile uses `build/web` |
| `backend/Dockerfile` | Multi-stage JDK 25 build → JRE 25 runtime |

**Firebase hosting gap (verified):** Production `lokal-eu.web.app` was last deployed **before** the Jul 2026 no-cache header commit. Live headers today:

- `/` → `max-age=3600` (stale shell risk)
- `/main.dart.js`, `/flutter_bootstrap.js` → `max-age=3600` (should be no-cache)
- `/index.html`, `/flutter_service_worker.js` → `no-cache` (partial config applied)

**Action:** Redeploy web after merging cache-header fixes. Command:

```bash
cd mobile
flutter build web --release --dart-define=API_BASE_URL=https://lokal-67ph.onrender.com
firebase deploy --only hosting
```

## Bugs / blockers (ranked)

1. **Firebase web not redeployed** — users can get hour-cached JS/HTML after releases. Fixed in repo; needs deploy.
2. **S3 upload errors returned HTTP 401** — `GlobalExceptionHandler` mapped all `IllegalStateException` to 401, including storage failures. **Fixed in this PR.**
3. **Web release builds without `--dart-define`** defaulted to `localhost:8080`. **Fixed:** release web builds now default to Render API URL.
4. **No CI** — no GitHub Actions; tests not run on push.
5. **JDK 25 required** — local dev/CI must use Java 25 (or Docker); Ubuntu default is 21.
6. **Profile screen** does not load producer pickup/delivery toggles from API (`UserDto` omits them) — minor UX gap.
7. **Render free tier cold start** — first request after idle can take 30–60s (observed ~200s on health check once).

## Not blockers for MVP viability

- Login, browse, list products, place orders: **working on prod**
- Photo uploads: **working** (R2 URLs in product responses)
- Google auth: demo only by design
- BOTH-role users can buy and sell

## Changes in this PR

1. `GlobalExceptionHandler` — storage/infra `IllegalStateException` → 500; auth-only → 401 (+ unit test)
2. `firebase.json` — add `/` and `**/*.js` no-cache rules (both root and `mobile/`)
3. `AppConfig.productionApiBaseUrl` + release-mode web default in `resolveApiBaseUrl()`
