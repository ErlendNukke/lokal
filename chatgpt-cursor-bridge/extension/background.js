const DEFAULTS = {
  bridgeUrl: "http://127.0.0.1:3847",
  bridgeToken: "change-me",
  autoSend: true,
  enabled: true,
};

async function getSettings() {
  const stored = await chrome.storage.sync.get(DEFAULTS);
  return { ...DEFAULTS, ...stored };
}

chrome.runtime.onInstalled.addListener(async () => {
  const current = await chrome.storage.sync.get(null);
  await chrome.storage.sync.set({ ...DEFAULTS, ...current });
});

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message?.type === "PING_BRIDGE") {
    pingBridge().then(sendResponse);
    return true;
  }
  if (message?.type === "SUBMIT_ORDERS") {
    submitOrders(message.text, message.source || "chatgpt-extension")
      .then(sendResponse)
      .catch((err) => sendResponse({ ok: false, error: String(err) }));
    return true;
  }
  if (message?.type === "GET_SETTINGS") {
    getSettings().then(sendResponse);
    return true;
  }
  return false;
});

async function pingBridge() {
  const settings = await getSettings();
  try {
    const res = await fetch(`${settings.bridgeUrl.replace(/\/$/, "")}/health`);
    const body = await res.json();
    return { ok: res.ok, body };
  } catch (err) {
    return { ok: false, error: String(err) };
  }
}

async function submitOrders(text, source) {
  const settings = await getSettings();
  if (!settings.enabled || !settings.autoSend) {
    return { ok: false, skipped: true, reason: "Bridge disabled or autoSend off" };
  }

  const res = await fetch(`${settings.bridgeUrl.replace(/\/$/, "")}/orders`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-bridge-token": settings.bridgeToken,
      "x-bridge-source": source,
    },
    body: JSON.stringify({ text, source }),
  });

  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    return { ok: false, status: res.status, body };
  }

  const jobs = body.jobs || [];
  const fresh = jobs.filter((j) => !j.duplicate && j.status !== "skipped");
  if (fresh.length > 0) {
    chrome.notifications.create({
      type: "basic",
      iconUrl: "icons/icon128.png",
      title: "Sent to Cursor",
      message:
        fresh.length === 1
          ? fresh[0].task.slice(0, 120)
          : `${fresh.length} orders queued for Cursor`,
    });
  }

  return { ok: true, body };
}
