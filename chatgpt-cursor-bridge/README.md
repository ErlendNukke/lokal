# ChatGPT Voice → Cursor Bridge (fully automatic)

Talk in **ChatGPT Voice**. When ChatGPT writes a `CURSOR_ORDER` block in the transcript, a Chrome extension detects it and your local bridge **immediately** queues a Cursor Agent run — no confirm click.

```text
ChatGPT Voice → transcript text → Chrome extension → local bridge → Cursor Agent
```

## Pieces

| Piece | Path | Role |
|-------|------|------|
| Bridge server | `bridge/` | Parses orders, dedupes, queues, calls Cursor |
| Chrome extension | `extension/` | Watches `chatgpt.com` / `chat.openai.com` and auto-POSTs new orders |
| ChatGPT instructions | `docs/chatgpt-instructions.md` | Teaches ChatGPT when to emit `CURSOR_ORDER` |

## Quick start

### 1. Bridge

```bash
cd chatgpt-cursor-bridge/bridge
cp .env.example .env
# edit .env — at least set BRIDGE_TOKEN to a secret
npm install
npm run dev
```

Open the dashboard URL printed in the terminal (includes `?token=`).

Modes in `.env`:

| `BRIDGE_MODE` | Behavior |
|---------------|----------|
| `dry-run` | Accepts orders, does **not** call Cursor (default, safe) |
| `cloud` | Creates Cursor Cloud Agents (`CURSOR_API_KEY` + `DEFAULT_REPO_URL`) |
| `local` | Runs `@cursor/sdk` against `LOCAL_CWD` (install SDK yourself) |

API key: [Cursor Dashboard → API Keys](https://cursor.com/dashboard/api).

For local mode:

```bash
npm install @cursor/sdk
```

### 2. Chrome extension

1. Chrome → `chrome://extensions` → Developer mode → **Load unpacked**
2. Select `chatgpt-cursor-bridge/extension`
3. Open the extension popup → set the same **Bridge token** as `.env` → Save & ping

### 3. ChatGPT

1. Use ChatGPT in the **browser** (`chatgpt.com`) so the extension can read the page  
2. Paste `docs/chatgpt-instructions.md` into custom instructions  
3. Start Voice, discuss, then say e.g. **“send that to Cursor”**

When the `CURSOR_ORDER` text appears in the chat, the toast says it was queued and the bridge dashboard updates.

## Order format

```text
CURSOR_ORDER:
repo: https://github.com/ErlendNukke/lokal
ref: main
task: Implement the change described here.
done when: Tests or manual checks that prove it works.
```

`repo` / `ref` are optional if defaults are set in `.env`.

## Safety

- Fully automatic means **no confirmation** once ChatGPT emits an order.
- Deduping ignores the same task hash for `DEDUP_MINUTES` (default 120).
- Bridge binds to `127.0.0.1` and requires `x-bridge-token`.
- Start with `BRIDGE_MODE=dry-run`, watch the dashboard, then switch to `cloud` or `local`.
- Keep `autoSend` enabled in the extension popup for full automation; uncheck to pause.

## API (local)

- `GET /health`
- `POST /orders` — `{ "text": "<page or transcript>" }` with header `x-bridge-token`
- `GET /jobs?token=...`
- `GET /events?token=...` — SSE job updates

## Limits

- Requires ChatGPT **in the browser** (not the native desktop app alone).
- ChatGPT Voice must leave a **text transcript** containing `CURSOR_ORDER`.
- This does not make Cursor speak back inside ChatGPT Voice; status is on the bridge dashboard / desktop notification.
