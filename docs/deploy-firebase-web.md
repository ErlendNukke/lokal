# Deploy Lokal Web — Firebase Hosting + PWA

Goal: public website for Lokal that talks to the live API  
`https://lokal-67ph.onrender.com`, with an **Install app** option on phones (PWA).

Est. time: **60–90 minutes** first time.

Do phases in order.

---

## What you will have at the end

| Piece | Where |
|--------|--------|
| Database | Neon (already done) |
| API | Render — `https://lokal-67ph.onrender.com` (already done) |
| Website | Firebase Hosting — `https://lokal-eu.web.app` |
| Phone “install” | PWA (Add to Home Screen / Install) from that website |
| Later | Real Play Store / App Store apps (separate phase) |

Flow:

```text
Phone browser / installed PWA  →  Firebase (static Flutter web)
                                      ↓
                               Render API
                                      ↓
                                    Neon
```

---

## Phase 0 — Prerequisites

- [ ] API live: `https://lokal-67ph.onrender.com/actuator/health` → `UP`
- [ ] Flutter SDK on your PC (`flutter` in PATH — we installed under `%USERPROFILE%\flutter`)
- [ ] Google account (same one you can use later for Play Console)
- [ ] Node.js 20+ installed ([nodejs.org](https://nodejs.org)) — needed for Firebase CLI

Check Node:

```bash
node -v
npm -v
```

---

## Phase 1 — Create Firebase project (~10 min)

1. Open [https://console.firebase.google.com](https://console.firebase.google.com)
2. **Add project** → name `Lokal` (or `lokal-app`)
3. Google Analytics: **optional** — can disable for simplicity
4. Create project → continue
5. In the project overview, click **Hosting** → **Get started**
6. Leave the console open; you’ll deploy from the terminal next

You do **not** need Firestore, Auth, or Functions for this — only **Hosting**.

---

## Phase 2 — Install Firebase CLI & log in (~5 min)

```bash
npm install -g firebase-tools
firebase login
```

Browser opens → sign in with the same Google account → allow access.

Confirm:

```bash
firebase projects:list
```

You should see your Lokal project.

---

## Phase 3 — Wire the repo for Hosting (~10 min)

From the **repo root** (`lokal/`):

```bash
firebase init hosting
```

Answer roughly like this:

| Prompt | Answer |
|--------|--------|
| Use existing project | Yes → select **Lokal** |
| Public directory | `mobile/build/web` |
| Single-page app | **Yes** (important for Flutter routes) |
| GitHub auto-deploy | **No** for now (optional later) |
| Overwrite `index.html` | **No** if asked (Flutter owns `web/`) |

This creates at repo root:

- `firebase.json`
- `.firebaserc`
- maybe `.firebase/`

Typical `firebase.json`:

```json
{
  "hosting": {
    "public": "mobile/build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ],
    "headers": [
      {
        "source": "/**",
        "headers": [
          { "key": "Cache-Control", "value": "no-cache" }
        ]
      },
      {
        "source": "/flutter_service_worker.js",
        "headers": [
          { "key": "Cache-Control", "value": "no-cache" }
        ]
      }
    ]
  }
}
```

(Exact headers can be refined when we implement; SPA rewrite is the critical part.)

---

## Phase 4 — Prepare Flutter web + PWA (~20–30 min)

### 4.1 Build with the live API URL

Always bake the Render URL into the build:

```bash
cd mobile
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://lokal-67ph.onrender.com
```

Output: `mobile/build/web/`

### 4.2 PWA checklist (so phones can “Install”)

Flutter web already has `web/manifest.json` and a service worker in release builds. We will tighten:

| Item | Why |
|------|-----|
| App name / short name “Lokal” in `manifest.json` | Shows under the home-screen icon |
| Theme / background colors | Splash / status bar look |
| Icons 192 + 512 PNG | Required for installability |
| `display: standalone` | Opens without browser chrome |
| HTTPS host (Firebase) | Required for install prompts |
| Service worker (Flutter release build) | Offline shell / install criteria |

**Android Chrome:** after visit, menu → **Install app**, or an in-app install banner we can add later.  
**iPhone Safari:** Share → **Add to Home Screen** (Apple doesn’t show the same install banner).

### 4.3 Optional UX later

- Soft “Install Lokal” button using `beforeinstallprompt` (Android/Chrome)
- Short tip for iOS: “Share → Add to Home Screen”

---

## Phase 5 — Allow the website in API CORS (~5 min)

On **Render** → lokal service → **Environment**, set:

```text
CORS_ORIGINS=https://YOUR-PROJECT.web.app,https://YOUR-PROJECT.firebaseapp.com
```

After first deploy you’ll know the exact URLs (Firebase shows them).  
If you add a custom domain later, add that too.

Save → wait for redeploy → confirm API still `UP`.

Without this, **web** login/API calls from Firebase can fail with CORS errors. Native apps don’t need it; the hosted website does.

---

## Phase 6 — Deploy to Firebase (~5 min)

From repo root:

```bash
firebase deploy --only hosting
```

Success output includes:

```text
Hosting URL: https://xxxxx.web.app
```

Open that URL on your laptop, then on your phone (same Wi‑Fi not required — it’s public).

### Smoke test on the live site

1. Site loads (Lokal UI)
2. Allow location
3. Login `anna@lokal.app` / `password123`
4. Products / map work
5. On Android Chrome: **Install app** / Add to Home Screen
6. On iPhone: Share → Add to Home Screen

---

## Phase 7 — Re-deploy workflow (ongoing)

Whenever you change the Flutter app:

```bash
cd mobile
flutter build web --release --dart-define=API_BASE_URL=https://lokal-67ph.onrender.com
cd ..
firebase deploy --only hosting
```

Optional later: GitHub Action that builds + deploys on push to `main`.

---

## Phase 8 — After the website works (not blocking today)

### A. Custom domain (optional)
Firebase Hosting → **Add custom domain** (e.g. `app.lokal.ee`) → DNS records → update `CORS_ORIGINS`.

### B. Real store apps (separate milestone)
1. Google Play (~$25) — `flutter build appbundle --dart-define=API_BASE_URL=…`
2. On the Firebase webpage, add “Get it on Google Play” button
3. Apple later (~$99/year + Mac/CI)

PWA install and Play Store can coexist: PWA for quick try, store for “real” install.

### C. Hardening
- Paid Render if cold starts annoy users
- Cloud image storage (R2/S3) when producers upload photos
- Privacy policy page linked from the site (needed before Play)

---

## Decision summary

| Question | Answer |
|----------|--------|
| Host | **Firebase Hosting** |
| Build | `flutter build web` with Render `API_BASE_URL` |
| Phone install from web | **Yes — PWA** (best on Android; iOS via Add to Home Screen) |
| Replace Play Store? | No — PWA is complementary; stores come later |

---

## Your immediate next clicks

1. Install **Node.js** if needed  
2. Create **Firebase project** + enable **Hosting**  
3. `npm i -g firebase-tools` → `firebase login`  
4. Tell me when that’s done — I’ll add `firebase.json`, polish PWA manifest/icons, build, and walk the first `firebase deploy` with you  

Or say **“implement now”** and I’ll prepare the repo files (firebase config, PWA manifest tweaks, deploy script) so you only do the Google login / project create steps.
