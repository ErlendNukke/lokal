# Firebase Hosting (Flutter web)

Project: **`lokal-eu`** → https://lokal-eu.web.app

Config lives in `mobile/firebase.json` and `mobile/.firebaserc` (no need to re-run `firebase init`).

## Deploy

```powershell
cd mobile

flutter build web --release --dart-define=API_BASE_URL=https://lokal-67ph.onrender.com

firebase deploy --only hosting
```

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
