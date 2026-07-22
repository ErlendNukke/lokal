# Image storage (S3 / MinIO / R2)

Lokal uploads product photos via `POST /api/uploads` and stores a public URL on the product.

Uploads are capped at **20 MB**, then resized to **thumbnail size (max 600px)** on the longest edge and re-encoded as **JPEG (~quality 0.75)**. Typical stored size is ~30–120 KB. Override with `MAX_UPLOAD_BYTES`, `IMAGE_MAX_EDGE_PX`, `IMAGE_JPEG_QUALITY`.

## iPhone uploads

iPhone photos are often **HEIC**. The API only stores JPEG/PNG/WebP/GIF, so the Flutter web app re-encodes picks to JPEG in the browser (Safari can decode HEIC) before `POST /api/uploads`.

If upload still fails on an old build: iPhone **Settings → Camera → Formats → Most Compatible** (saves JPG).

Flutter web (CanvasKit) will **not show** R2 images unless the bucket allows cross-origin GETs. Seed Unsplash photos work because they send `Access-Control-Allow-Origin: *`; a fresh R2 bucket does not.

In Cloudflare → **R2** → bucket `lokal` → **Settings** → **CORS Policy** → **Add**:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

Then hard-refresh the app. Uploaded thumbs should appear.

| `STORAGE_TYPE` | Backend | Survives Render restarts? |
|----------------|---------|---------------------------|
| `local` (default) | Files under `UPLOAD_PATH`, served at `/uploads/**` | No on free Render (`/tmp`) |
| `s3` | MinIO, Cloudflare R2, or AWS S3 | Yes |

## Local MinIO (recommended for full stack)

```bash
docker compose up -d minio minio-init
```

Console: http://localhost:9001 (user `lokal` / `lokalsecret`)

Run the API against MinIO:

```bash
cd backend
export STORAGE_TYPE=s3
export S3_ENDPOINT=http://localhost:9000
export S3_REGION=us-east-1
export S3_BUCKET=lokal
export S3_ACCESS_KEY=lokal
export S3_SECRET_KEY=lokalsecret
export S3_PUBLIC_BASE_URL=http://localhost:9000/lokal
export S3_PATH_STYLE=true
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

Or bring up API + DB + MinIO together:

```bash
docker compose --profile full up --build
```

## Cloudflare R2 (good for production on Render)

1. Cloudflare dashboard → **R2** → create bucket `lokal`
2. Enable **Public access** (r2.dev subdomain or custom domain)
3. Create an API token with Object Read & Write
4. On Render, set:

| Key | Example |
|-----|---------|
| `STORAGE_TYPE` | `s3` |
| `S3_ENDPOINT` | `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` |
| `S3_REGION` | `auto` |
| `S3_BUCKET` | `lokal` |
| `S3_ACCESS_KEY` | *(R2 access key id)* |
| `S3_SECRET_KEY` | *(R2 secret)* |
| `S3_PUBLIC_BASE_URL` | `https://pub-xxxx.r2.dev` |
| `S3_PATH_STYLE` | `false` |
| `S3_PUBLIC_READ` | `false` |
| `S3_CREATE_BUCKET` | `false` |

`S3_PUBLIC_BASE_URL` is what the Flutter app loads in `<img>` / `CachedNetworkImage` — it must be browser-reachable HTTPS.

## AWS S3

Same `STORAGE_TYPE=s3` vars. Typical public base URL:

```text
https://YOUR-BUCKET.s3.eu-central-1.amazonaws.com
```

Leave `S3_ENDPOINT` empty. Set bucket policy (or ACL) so objects are publicly readable, or put CloudFront in front and use that as `S3_PUBLIC_BASE_URL`.

## Env reference

| Variable | Purpose |
|----------|---------|
| `STORAGE_TYPE` | `local` or `s3` |
| `S3_ENDPOINT` | Custom endpoint (MinIO / R2). Empty for AWS |
| `S3_REGION` | Region (`us-east-1` for MinIO, `auto` for R2) |
| `S3_BUCKET` | Bucket name |
| `S3_ACCESS_KEY` / `S3_SECRET_KEY` | Credentials |
| `S3_PUBLIC_BASE_URL` | Public URL prefix returned to clients |
| `S3_PATH_STYLE` | `true`/`false`; auto-true when endpoint is set |
| `S3_PUBLIC_READ` | Try `public-read` ACL on upload (falls back if provider rejects) |
| `S3_CREATE_BUCKET` | Create bucket on startup if missing |
