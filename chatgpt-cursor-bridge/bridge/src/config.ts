import { config as loadEnv } from "dotenv";
import path from "node:path";
import { fileURLToPath } from "node:url";
import type { BridgeConfig, BridgeMode } from "./types.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
loadEnv({ path: path.join(__dirname, "../.env") });

function modeFromEnv(value: string | undefined): BridgeMode {
  if (value === "cloud" || value === "local" || value === "dry-run") return value;
  return "dry-run";
}

export function loadConfig(): BridgeConfig {
  const bridgeToken = process.env.BRIDGE_TOKEN?.trim() || "change-me";
  const cursorApiKey = process.env.CURSOR_API_KEY?.trim() || undefined;
  const mode = modeFromEnv(process.env.BRIDGE_MODE);

  if (mode !== "dry-run" && !cursorApiKey) {
    throw new Error(
      "CURSOR_API_KEY is required when BRIDGE_MODE is cloud or local. Set BRIDGE_MODE=dry-run to test without a key.",
    );
  }

  if (mode === "local" && !process.env.LOCAL_CWD?.trim()) {
    throw new Error("LOCAL_CWD is required when BRIDGE_MODE=local");
  }

  return {
    mode,
    port: Number(process.env.PORT || 3847),
    host: process.env.HOST || "127.0.0.1",
    bridgeToken,
    cursorApiKey,
    defaultRepoUrl: process.env.DEFAULT_REPO_URL?.trim() || undefined,
    defaultRef: process.env.DEFAULT_REF?.trim() || "main",
    autoCreatePr: (process.env.AUTO_CREATE_PR || "true").toLowerCase() !== "false",
    cursorModel: process.env.CURSOR_MODEL?.trim() || "composer-2.5",
    localCwd: process.env.LOCAL_CWD?.trim() || undefined,
    dedupMinutes: Number(process.env.DEDUP_MINUTES || 120),
  };
}
