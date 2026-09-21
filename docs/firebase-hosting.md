# Firebase Hosting (Flutter web)

Project: **`lokal-eu`** → https://lokal-eu.web.app

Config lives in `mobile/firebase.json` and `mobile/.firebaserc` (no need to re-run `firebase init`).

## Deploy (manual)

From repo root (uses root `firebase.json` → `mobile/build/web`):

```bash
cd mobile
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://lokal-67ph.onrender.com
cd ..
firebase deploy --only hosting --project lokal-eu
```

Requires `firebase login` once on the machine, or `firebase login:ci` → set `FIREBASE_TOKEN` for CI.

## Deploy (GitHub Actions)

Workflow: `.github/workflows/firebase-hosting.yml` — runs on `workflow_dispatch` and on pushes to `main` that touch `mobile/`, `firebase.json`, or `.firebaserc`.

**One-time setup:** add repo secret `FIREBASE_SERVICE_ACCOUNT` with the JSON from Firebase Console → Project **lokal-eu** → Project settings → Service accounts → Generate new private key.

## Render CORS

```env
CORS_ORIGINS=https://lokal-eu.web.app
```

## First-time CLI on this machine

```powershell
firebase login
cd mobile
firebase use lokal-eu
```
