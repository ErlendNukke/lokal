import cors from "cors";
import express from "express";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import type { BridgeConfig } from "./types.js";
import { extractOrders } from "./parser.js";
import { OrderQueue } from "./queue.js";
import { JobStore } from "./store.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function createServer(config: BridgeConfig) {
  const app = express();
  const store = new JobStore(config.dedupMinutes);
  const queue = new OrderQueue(config, store);

  app.use(
    cors({
      origin: true,
    }),
  );
  app.use(express.json({ limit: "1mb" }));
  app.use(express.text({ type: ["text/plain", "text/*"], limit: "1mb" }));

  function authorize(req: express.Request, res: express.Response): boolean {
    const header = req.header("x-bridge-token") || "";
    const query = typeof req.query.token === "string" ? req.query.token : "";
    const token = header || query;
    if (!token || token !== config.bridgeToken) {
      res.status(401).json({ error: "Invalid or missing x-bridge-token" });
      return false;
    }
    return true;
  }

  app.get("/health", (_req, res) => {
    res.json({
      ok: true,
      mode: config.mode,
      defaultRepoUrl: config.defaultRepoUrl ?? null,
      autoCreatePr: config.autoCreatePr,
    });
  });

  app.get("/", (_req, res) => {
    res.type("html").send(
      fs.readFileSync(path.join(__dirname, "dashboard.html"), "utf8"),
    );
  });

  app.get("/jobs", (req, res) => {
    if (!authorize(req, res)) return;
    res.json({ jobs: store.list() });
  });

  app.get("/events", (req, res) => {
    if (!authorize(req, res)) return;
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.flushHeaders?.();

    res.write(`event: hello\ndata: ${JSON.stringify({ mode: config.mode })}\n\n`);

    const unsubscribe = queue.onUpdate((job) => {
      res.write(`event: job\ndata: ${JSON.stringify(job)}\n\n`);
    });

    req.on("close", () => {
      unsubscribe();
    });
  });

  /**
   * Fully automatic ingest:
   * - { text: "full page / transcript" } → extract all new CURSOR_ORDER blocks
   * - { order: "CURSOR_ORDER:\\n..." } → parse one blob
   * - raw text body with CURSOR_ORDER
   */
  app.post("/orders", (req, res) => {
    if (!authorize(req, res)) return;

    const source =
      (typeof req.body?.source === "string" && req.body.source) ||
      req.header("x-bridge-source") ||
      "extension";

    let text = "";
    if (typeof req.body === "string") {
      text = req.body;
    } else if (req.body && typeof req.body === "object") {
      text =
        (typeof req.body.order === "string" && req.body.order) ||
        (typeof req.body.text === "string" && req.body.text) ||
        "";
    }

    if (!text.trim()) {
      res.status(400).json({ error: "Expected JSON { text | order } or plain text" });
      return;
    }

    const orders = extractOrders(text);
    if (orders.length === 0) {
      res.status(422).json({
        error: "No CURSOR_ORDER block found",
        hint: "Ask ChatGPT Voice to emit a CURSOR_ORDER block when you want Cursor to build.",
      });
      return;
    }

    const accepted = orders.map((order) => queue.enqueue(order, source));
    res.status(202).json({
      accepted: accepted.length,
      jobs: accepted.map(({ job, duplicate }) => ({
        id: job.id,
        status: job.status,
        hash: job.order.hash,
        duplicate,
        task: job.order.task,
      })),
    });
  });

  app.post("/parse", (req, res) => {
    if (!authorize(req, res)) return;
    const text =
      typeof req.body === "string"
        ? req.body
        : typeof req.body?.text === "string"
          ? req.body.text
          : "";
    res.json({ orders: extractOrders(text) });
  });

  return { app, store, queue };
}
