const enabledEl = document.getElementById("enabled");
const autoSendEl = document.getElementById("autoSend");
const bridgeUrlEl = document.getElementById("bridgeUrl");
const bridgeTokenEl = document.getElementById("bridgeToken");
const statusEl = document.getElementById("status");
const saveEl = document.getElementById("save");

async function load() {
  const settings = await chrome.runtime.sendMessage({ type: "GET_SETTINGS" });
  enabledEl.checked = !!settings.enabled;
  autoSendEl.checked = !!settings.autoSend;
  bridgeUrlEl.value = settings.bridgeUrl || "";
  bridgeTokenEl.value = settings.bridgeToken || "";
}

saveEl.addEventListener("click", async () => {
  statusEl.className = "";
  statusEl.textContent = "Saving…";
  await chrome.storage.sync.set({
    enabled: enabledEl.checked,
    autoSend: autoSendEl.checked,
    bridgeUrl: bridgeUrlEl.value.trim(),
    bridgeToken: bridgeTokenEl.value,
  });
  const ping = await chrome.runtime.sendMessage({ type: "PING_BRIDGE" });
  if (ping?.ok) {
    statusEl.className = "ok";
    statusEl.textContent = `Bridge ok (mode=${ping.body?.mode})`;
  } else {
    statusEl.className = "err";
    statusEl.textContent = ping?.error || "Bridge unreachable. Is the server running?";
  }
});

load();
