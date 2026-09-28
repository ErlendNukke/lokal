# Lokal web walkthrough (Playwright / WebKit)

Automated iPhone 14–sized walkthrough of the Flutter web app against a **local** API (never production).

## Prerequisites

- JDK 25 (`backend/`)
- Flutter stable (Dart ^3.8)
- Node.js 20+

## Run locally

1. Start the API (H2 + seed data):

   ```bash
   cd backend
   ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
   ```

2. Run the walkthrough (builds release web with semantics, serves it, runs Playwright):

   ```bash
   ./e2e/run-local.sh
   ```

Screenshots are written to `WALKTHROUGH_DIR` (default `/opt/cursor/artifacts/walkthrough`).

### Build flags

- `API_BASE_URL` — passed to `flutter build web` (default `http://localhost:8080`).
- `ENABLE_SEMANTICS=true` — **only** used for this e2e build so Playwright can drive CanvasKit; production/release builds omit it.

### WebKit / Playwright notes

- Text fields: use a single click plus `pressSequentially` (not triple-click or `fill()`), so Flutter `TextEditingController` values stay in sync on WebKit.
- Producer **Salvesta toode**: the app POSTs correctly when the form is valid; earlier “no POST” failures were harness input/sync issues, not a Safari-only app bug.
- **Buyer-only orders**: `UserRole.PRODUCER` is blocked from ordering; `BUYER` and `BOTH` can order. The walkthrough uses **Anna** (`anna@lokal.app`, buyer-only) as the primary UI order flow on Mari’s products.

## CI

The `e2e-walkthrough` job in `.github/workflows/ci.yml` runs on PRs that touch `mobile/**`, `backend/**`, or `e2e/**`.
