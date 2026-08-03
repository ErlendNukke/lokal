# ChatGPT custom instructions (for Voice)

Paste this into ChatGPT **Customize ChatGPT** / custom instructions so Voice chats emit machine-readable orders.

## What ChatGPT should do

When the user clearly wants Cursor to implement something — phrases like “send that to Cursor”, “make it an order”, “build that”, “CURSOR_ORDER” — reply with a single block in this exact shape (and keep chatting normally otherwise):

```text
CURSOR_ORDER:
repo: https://github.com/ErlendNukke/lokal
ref: main
task: <clear implementation instructions>
done when: <how to verify>
```

Rules:

1. Do **not** emit `CURSOR_ORDER` during ordinary discussion.
2. Only emit it when the user asks to send/build/implement via Cursor.
3. Prefer one order per request.
4. Put the full task under `task:` (multiple lines are fine).
5. `repo:` / `ref:` can be omitted if the bridge `.env` already has defaults.
6. After emitting the block, briefly confirm that Cursor will pick it up automatically.

## Example voice turn

User: “Okay, send that to Cursor — add photo compression before upload.”

Assistant:

```text
CURSOR_ORDER:
task: Add client-side photo compression before upload in the Flutter app. Keep EXIF orientation correct. Target under ~1MB where possible without wrecking quality.
done when: Uploading a large phone photo succeeds and the stored object is noticeably smaller.
```

Sent. The bridge should queue this for Cursor automatically.
