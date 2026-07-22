# Deploy Lokal — detailed next steps (Neon + Render)

Goal: public HTTPS API + real Postgres, then point the Flutter app at it.  
Est. time: **45–90 minutes** the first time (accounts + first Docker build).

Do these in order. Don’t skip ahead to Flutter until health + login work on the public URL.

---

## Phase 0 — Commit deploy files (if not pushed yet)

On your machine, the deploy wiring lives in:

- `render.yaml`
- `docs/deploy-neon-render.md` (this file)
- `backend/Dockerfile`, `backend/.dockerignore`
- prod tweaks in `application.yml`

If those aren’t on GitHub `main` yet, commit and push first — Render builds from the repo.

---

## Phase 1 — Create Neon database (~10 min)

### 1.1 Sign up
1. Open [https://console.neon.tech](https://console.neon.tech)
2. Sign up with GitHub (simplest)
3. Skip optional marketing prompts

### 1.2 Create project
1. **New Project**
2. Name: `lokal` (or anything)
3. **Region:** pick EU close to you (e.g. Frankfurt / Frankfurt am Main) — same region family as Render later reduces latency
4. Postgres version: default is fine
5. Create project

### 1.3 Copy connection details
On the project dashboard, open **Connect** / **Connection details**:

1. Prefer **JDBC** connection string (not `postgresql://…` URI)
2. Prefer **pooled** connection if shown (PgBouncer) — better for free Render
3. Copy separately:
   - full JDBC URL
   - role / user
   - password (click reveal if hidden)

### 1.4 Fix the JDBC URL
The URL must require SSL. If there is no `sslmode`:

```text
jdbc:postgresql://ep-XXXX.eu-central-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require
```

If the URL already has `?`, use `&sslmode=require` instead of a second `?`.

**Save these three values in a notepad** (you’ll paste them into Render):

| What | Example |
|------|---------|
| `DATABASE_URL` | `jdbc:postgresql://ep-….neon.tech/neondb?sslmode=require` |
| `DATABASE_USER` | `neondb_owner` |
| `DATABASE_PASSWORD` | `••••••••` |

Leave the Neon tab open. Don’t create tables by hand — Lokal’s Liquibase does that on first API start.

---

## Phase 2 — Deploy API on Render (~20–40 min including build)

### 2.1 Sign up and link GitHub
1. Open [https://dashboard.render.com](https://dashboard.render.com)
2. Sign up (GitHub login)
3. Allow Render to access the **`ErlendNukke/lokal`** repository  
   (if the org/user list is limited, grant access to that repo)

### 2.2 Create the web service (pick one)

**Option A — Blueprint (matches repo `render.yaml`)**  
1. Dashboard → **New** → **Blueprint**  
2. Select `lokal` repo / `main` branch  
3. Apply / create  
4. You’ll still need to fill secrets marked `sync: false` (database vars, etc.)

**Option B — Manual Web Service (clearest first time)**  
1. **New** → **Web Service**  
2. Connect repo `lokal`  
3. Settings:
   - **Language / Runtime:** Docker  
   - **Root directory:** leave empty (repo root) **or** set Dockerfile path as below  
   - **Dockerfile path:** `backend/Dockerfile`  
   - **Docker build context directory:** `backend`  
   - **Branch:** `main`  
   - **Instance type:** Free  
   - **Region:** Frankfurt (or closest to Neon)

### 2.3 Environment variables
In the service → **Environment**, add:

| Key | Value | Notes |
|-----|--------|--------|
| `SPRING_PROFILES_ACTIVE` | `prod` | Required |
| `DATABASE_URL` | *(Neon JDBC URL)* | Must include `sslmode=require` |
| `DATABASE_USER` | *(Neon user)* | |
| `DATABASE_PASSWORD` | *(Neon password)* | |
| `JWT_SECRET` | 32+ random chars | Don’t use the short default; generate e.g. in PowerShell: `[Convert]::ToBase64String((1..48\|%{Get-Random -Max 256}) -as [byte[]])` |
| `STORAGE_TYPE` | `s3` | Use cloud object storage so photos survive restarts — see `docs/storage-s3.md` |
| `S3_ENDPOINT` | *(R2/MinIO endpoint)* | Empty for AWS S3 |
| `S3_REGION` | `auto` (R2) or `eu-central-1` | |
| `S3_BUCKET` | `lokal` | |
| `S3_ACCESS_KEY` / `S3_SECRET_KEY` | *(provider keys)* | |
| `S3_PUBLIC_BASE_URL` | `https://pub-….r2.dev` | Browser-reachable HTTPS prefix for uploaded objects |
| `CORS_ORIGINS` | *(leave empty for now)* | Only needed for hosted Flutter **web** later |

Also ensure the service listens on Render’s port: our app uses `PORT` (Render sets this; default in image is 8080).

### 2.4 First deploy
1. Click **Create Web Service** / **Deploy**
2. Open **Logs**
3. Expect:
   - Docker pull of Java 25 images
   - `mvn package` (several minutes)
   - Spring Boot start
   - Liquibase changelog run (`001-schema`, `002-sample-data`)
   - `Started LokalApplication`
4. If it fails, read the **last 30 lines** of logs first — usual issues:
   - wrong JDBC URL / missing `sslmode`
   - wrong user/password
   - build timeout (retry once; free tier can be slow)

### 2.5 Confirm the public URL
Your API will look like:

```text
https://lokal-api-xxxx.onrender.com
```

(Exact name depends on what you chose.)

If you still use **local** uploads (`STORAGE_TYPE=local`), set `PUBLIC_BASE_URL` to:

```text
https://lokal-api-xxxx.onrender.com/uploads
```

Prefer **`STORAGE_TYPE=s3`** with Cloudflare R2 (or S3) so photos persist — see `docs/storage-s3.md`.

Redeploy if you changed env vars after the first boot.

---

## Phase 3 — Verify API before touching Flutter (~5 min)

### 3.1 Health (may be slow the first time)
Free services **sleep**. First request after idle can take **30–90 seconds**. Wait.

```bash
curl -s https://YOUR-SERVICE.onrender.com/actuator/health
```

Expect something like: `{"status":"UP",...}`

### 3.2 Login (demo seed user)
```bash
curl -s -X POST https://YOUR-SERVICE.onrender.com/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"anna@lokal.app\",\"password\":\"password123\"}"
```

(On PowerShell, write JSON to a file and use `curl.exe --data-binary "@file.json"` if escaping breaks.)

Expect a JSON body with `token` and `user`.

### 3.3 Products
```bash
curl -s "https://YOUR-SERVICE.onrender.com/api/products?lat=59.437&lng=24.7536&radiusKm=10"
```

Expect a JSON array of products.

**Do not continue until all three work.**

---

## Phase 4 — Run Flutter against the live API (~10 min)

### 4.1 Chrome / web (fastest check)
```bash
cd mobile
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com
```

1. Allow location when the browser asks  
2. Log in: `anna@lokal.app` / `password123`  
3. Confirm browse map loads products  

If login fails with network/CORS errors on **web only**, set:

```text
CORS_ORIGINS=http://localhost:<chrome-debug-port>
```

…or temporarily your exact web origin. Native Android/iOS do **not** need CORS.

### 4.2 Phone / emulator later
Same `--dart-define=API_BASE_URL=…`  
Android emulator can use the HTTPS Render URL directly (no `10.0.2.2`).

---

## Phase 5 — What “done for now” looks like

You’re done with this milestone when:

- [ ] Neon project exists with Lokal tables (created by Liquibase)
- [ ] Render URL returns `UP` on `/actuator/health`
- [ ] Demo login returns a JWT
- [ ] Flutter (Chrome) talks to that URL and shows nearby products

---

## Phase 6 — After that (not today unless you want)

### Play Store (next big milestone)
1. Google Play Console account (~$25 one-time)
2. App icon, screenshots, privacy policy URL
3. Build:
   ```bash
   flutter build appbundle --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com
   ```
4. Upload AAB → internal testing track → testers → production

### App Store (later)
1. Apple Developer Program (~$99/year)
2. Mac or cloud Mac CI for signing
3. TestFlight → review

### Hardening worth doing before real users
1. Strong unique `JWT_SECRET` (rotate if it was ever committed)
2. Paid Render (or always-on host) if cold starts annoy testers
3. Cloudflare R2 / S3 for photos — wire `STORAGE_TYPE=s3` (see `docs/storage-s3.md`)
4. Change demo passwords / disable seed users in real prod
5. Privacy policy + location disclosure (you already have iOS location strings)

---

## Quick troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| Health hangs then works | Free tier cold start — wait |
| `Connection refused` / DB errors in logs | Bad `DATABASE_*` or missing `sslmode=require` |
| Build fails on Maven/Java | Check Dockerfile on `main`; rebuild |
| Login 401 | Wrong password; seed only runs on empty DB |
| Flutter can’t reach API | Wrong `API_BASE_URL` (must be `https://…`, no trailing slash) |
| Web CORS errors | Set `CORS_ORIGINS` to the exact web origin |
| Photos disappear | Expected on free `/tmp` with `STORAGE_TYPE=local` — set `STORAGE_TYPE=s3` (`docs/storage-s3.md`) |

---

## Your immediate next click

1. **Right now:** [Neon console](https://console.neon.tech) → create project → copy JDBC + user + password  
2. **Then:** [Render](https://dashboard.render.com) → new Docker web service from `backend/Dockerfile` → paste env vars → deploy  
3. **Then:** hit `/actuator/health` and login  
4. **Then:** `flutter run -d chrome --dart-define=API_BASE_URL=https://…`
