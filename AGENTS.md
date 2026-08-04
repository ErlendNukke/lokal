# AGENTS.md

## Cursor Cloud specific instructions

This is a monorepo with three components. Standard commands live in the per-component
docs; this section only captures non-obvious, durable setup/run caveats.

- `backend/` — Spring Boot 4.1 / Java 25 API (see `README.md` and `docs/`).
- `mobile/` — Flutter app for iOS / Android / Web (see `mobile/README.md`).
- `chatgpt-cursor-bridge/` — auxiliary Node/TypeScript dev tool (see its `README.md`).

### Pre-installed toolchain (baked into the VM snapshot)

- Java 25 (Temurin) at `/opt/java/current`; it is the default `java`/`javac` (via
  `update-alternatives`) and `JAVA_HOME` is exported in `~/.bashrc`. The project
  requires Java 25 — Java 21 will not compile it.
- Flutter (stable) + Dart at `/opt/flutter`, symlinked into `/usr/local/bin`.
  Flutter web is enabled.
- Node/npm are symlinked into `/usr/local/bin` (installed via nvm). Google Chrome is
  at `/usr/local/bin/google-chrome` for `flutter run -d chrome`.
- The update script only refreshes JS/Dart deps (`npm install` for the bridge and
  `flutter pub get` for mobile). Maven deps are cached in `~/.m2` and `./mvnw`
  resolves them on demand, so the backend is intentionally not in the update script.

### Backend (`backend/`)

- Use the `./mvnw` wrapper; there is no system-wide `mvn`.
- Run in dev mode with the in-memory H2 database (no Postgres/MinIO needed):
  `./mvnw spring-boot:run -Dspring-boot.run.profiles=dev` → http://localhost:8080.
- The dev profile seeds demo accounts (password `password123`) and sample products
  via Liquibase; all data resets on every restart because H2 is in-memory.
- Health: `GET /actuator/health`. API smoke checklist is in `docs/api-smoke.md`.
- `docker-compose.yml` (Postgres + MinIO + prod `api`) is for the prod profile only;
  it is not required for local dev.

### Mobile (`mobile/`)

- Lint with `flutter analyze` (the repo currently has pre-existing `info`/`warning`
  lints but no errors) and test with `flutter test`.
- For a headless VM, run the web target against the local API:
  `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8090 --dart-define=API_BASE_URL=http://localhost:8080`.
- Gotcha: the `web-server` device compiles Dart→JS on the first browser hit, so the
  page is blank for ~20–30s on first load — wait and refresh once.

### chatgpt-cursor-bridge (`chatgpt-cursor-bridge/bridge`)

- Copy `.env.example` to `.env` and set `BRIDGE_TOKEN`. The default
  `BRIDGE_MODE=dry-run` is safe: it queues orders but never calls Cursor, so it needs
  no `CURSOR_API_KEY` to run/test.
- `npm run dev` binds to `127.0.0.1:3847`; health at `GET /health`, dashboard at
  `/?token=<BRIDGE_TOKEN>`. `npm test` and `npm run typecheck` cover it.
