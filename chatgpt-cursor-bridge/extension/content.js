(() => {
  const ORDER_RE = /CURSOR_ORDER\s*:?/i;
  const seenHashes = new Set();
  let scanTimer = null;
  let toastEl = null;

  function ensureToast() {
    if (toastEl) return toastEl;
    toastEl = document.createElement("div");
    toastEl.id = "ccb-toast";
    toastEl.setAttribute("aria-live", "polite");
    document.documentElement.appendChild(toastEl);
    return toastEl;
  }

  function toast(message, kind = "ok") {
    const el = ensureToast();
    el.textContent = message;
    el.dataset.kind = kind;
    el.dataset.show = "1";
    clearTimeout(toast._t);
    toast._t = setTimeout(() => {
      el.dataset.show = "0";
    }, 4200);
  }

  function simpleHash(str) {
    let h = 0;
    for (let i = 0; i < str.length; i++) {
      h = (Math.imul(31, h) + str.charCodeAt(i)) | 0;
    }
    return `h${h}`;
  }

  function extractRawBlocks(text) {
    const blocks = [];
    const re = /(?:^|\n)\s*(?:```(?:cursor_order|CURSOR_ORDER)?\s*\n)?CURSOR_ORDER\s*:?\s*\n/gi;
    const matches = [...text.matchAll(re)];
    for (let i = 0; i < matches.length; i++) {
      const m = matches[i];
      const start = m.index;
      const end = i + 1 < matches.length ? matches[i + 1].index : text.length;
      const slice = text.slice(start, end).trim();
      // Keep a stable-ish fingerprint of the order body
      const bodyStart = slice.search(/CURSOR_ORDER\s*:?/i);
      const body = slice.slice(bodyStart).slice(0, 2000);
      blocks.push({ raw: slice, fingerprint: simpleHash(body.replace(/\s+/g, " ").toLowerCase()) });
    }
    return blocks;
  }

  async function scan() {
    const settings = await chrome.runtime.sendMessage({ type: "GET_SETTINGS" });
    if (!settings?.enabled || !settings?.autoSend) return;

    const text = document.body?.innerText || "";
    if (!ORDER_RE.test(text)) return;

    const blocks = extractRawBlocks(text);
    const novel = blocks.filter((b) => !seenHashes.has(b.fingerprint));
    if (novel.length === 0) return;

    // Mark immediately to avoid double-submit while network in flight
    for (const b of novel) seenHashes.add(b.fingerprint);

    const combined = novel.map((b) => b.raw).join("\n\n");
    toast(`Sending ${novel.length} CURSOR_ORDER${novel.length > 1 ? "s" : ""} to Cursor…`, "pending");

    const result = await chrome.runtime.sendMessage({
      type: "SUBMIT_ORDERS",
      text: combined,
      source: "chatgpt-voice-page",
    });

    if (!result?.ok) {
      // Allow retry if bridge was down
      for (const b of novel) seenHashes.delete(b.fingerprint);
      toast(result?.body?.error || result?.error || result?.reason || "Bridge send failed", "err");
      return;
    }

    const jobs = result.body?.jobs || [];
    const fresh = jobs.filter((j) => !j.duplicate);
    const dupes = jobs.length - fresh.length;
    if (fresh.length === 0 && dupes > 0) {
      toast("Order already sent (deduped)", "ok");
    } else {
      toast(`Queued ${fresh.length} order(s) for Cursor`, "ok");
    }
  }

  function scheduleScan() {
    clearTimeout(scanTimer);
    scanTimer = setTimeout(() => {
      scan().catch((err) => console.warn("[ccb]", err));
    }, 700);
  }

  const observer = new MutationObserver(scheduleScan);
  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
    characterData: true,
  });

  // Voice transcripts often settle after a short delay
  setInterval(scheduleScan, 2500);
  scheduleScan();

  console.info("[ccb] ChatGPT → Cursor Bridge watching for CURSOR_ORDER (fully automatic)");
})();
