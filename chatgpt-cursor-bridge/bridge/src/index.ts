import { loadConfig } from "./config.js";
import { createServer } from "./server.js";

const config = loadConfig();
const { app } = createServer(config);

app.listen(config.port, config.host, () => {
  console.log(
    `[bridge] listening on http://${config.host}:${config.port} (mode=${config.mode})`,
  );
  console.log(
    `[bridge] dashboard: http://${config.host}:${config.port}/?token=${encodeURIComponent(config.bridgeToken)}`,
  );
  console.log(
    "[bridge] fully automatic: Chrome extension posts new CURSOR_ORDER blocks here with no confirmation",
  );
  if (config.bridgeToken === "change-me") {
    console.warn(
      "[bridge] WARNING: BRIDGE_TOKEN is still 'change-me'. Set a secret in bridge/.env and the extension options.",
    );
  }
});
