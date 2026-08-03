import { createHash } from "node:crypto";
import type { CursorOrder } from "./types.js";

const ORDER_START = /(?:^|\n)\s*(?:```(?:cursor_order|CURSOR_ORDER)?\s*\n)?CURSOR_ORDER\s*:?\s*\n/gi;

function normalizeTask(task: string): string {
  return task.replace(/\s+/g, " ").trim().toLowerCase();
}

export function hashOrder(task: string, repo?: string, ref?: string): string {
  return createHash("sha256")
    .update([normalizeTask(task), repo ?? "", ref ?? ""].join("|"))
    .digest("hex")
    .slice(0, 16);
}

function parseFields(block: string): Omit<CursorOrder, "raw" | "hash"> | null {
  const lines = block
    .replace(/```\s*$/g, "")
    .split("\n")
    .map((l) => l.replace(/\r$/, ""));

  let repo: string | undefined;
  let ref: string | undefined;
  let doneWhen: string | undefined;
  const taskLines: string[] = [];
  let section: "none" | "task" | "done" = "none";

  for (const line of lines) {
    const repoMatch = line.match(/^\s*repo\s*:\s*(.+)\s*$/i);
    if (repoMatch) {
      repo = repoMatch[1].trim();
      section = "none";
      continue;
    }

    const refMatch = line.match(/^\s*ref\s*:\s*(.+)\s*$/i);
    if (refMatch) {
      ref = refMatch[1].trim();
      section = "none";
      continue;
    }

    const doneMatch = line.match(/^\s*done\s*when\s*:\s*(.*)$/i);
    if (doneMatch) {
      doneWhen = doneMatch[1].trim();
      section = doneWhen ? "none" : "done";
      continue;
    }

    const taskMatch = line.match(/^\s*task\s*:\s*(.*)$/i);
    if (taskMatch) {
      const rest = taskMatch[1].trim();
      if (rest) taskLines.push(rest);
      section = "task";
      continue;
    }

    if (section === "task") {
      if (!line.trim()) {
        // blank line ends task unless more indented content follows later
        continue;
      }
      if (/^\s*[a-z][a-z0-9 _-]*\s*:/i.test(line) && !/^\s*task\s*:/i.test(line)) {
        section = "none";
        // re-process as a field line
        const againRepo = line.match(/^\s*repo\s*:\s*(.+)\s*$/i);
        const againRef = line.match(/^\s*ref\s*:\s*(.+)\s*$/i);
        const againDone = line.match(/^\s*done\s*when\s*:\s*(.*)$/i);
        if (againRepo) repo = againRepo[1].trim();
        else if (againRef) ref = againRef[1].trim();
        else if (againDone) doneWhen = againDone[1].trim();
        continue;
      }
      taskLines.push(line.trim());
      continue;
    }

    if (section === "done" && line.trim()) {
      doneWhen = (doneWhen ? `${doneWhen} ` : "") + line.trim();
    }
  }

  const task = taskLines.join("\n").trim();
  if (!task) return null;
  return { task, repo, ref, doneWhen };
}

/**
 * Extract all CURSOR_ORDER blocks from ChatGPT transcript / page text.
 */
export function extractOrders(text: string): CursorOrder[] {
  if (!text || !/CURSOR_ORDER/i.test(text)) return [];

  const orders: CursorOrder[] = [];
  const seen = new Set<string>();
  const matches = [...text.matchAll(ORDER_START)];

  for (let i = 0; i < matches.length; i++) {
    const match = matches[i];
    const start = (match.index ?? 0) + match[0].length;
    const end = i + 1 < matches.length ? (matches[i + 1].index ?? text.length) : text.length;
    let block = text.slice(start, end);

    // Stop at next markdown fence close or obvious chat boundary markers
    const fenceClose = block.search(/\n```/);
    if (fenceClose >= 0) block = block.slice(0, fenceClose);

    const parsed = parseFields(block);
    if (!parsed) continue;

    const hash = hashOrder(parsed.task, parsed.repo, parsed.ref);
    if (seen.has(hash)) continue;
    seen.add(hash);

    orders.push({
      raw: `CURSOR_ORDER:\n${block.trim()}`,
      task: parsed.task,
      repo: parsed.repo,
      ref: parsed.ref,
      doneWhen: parsed.doneWhen,
      hash,
    });
  }

  return orders;
}

export function buildAgentPrompt(order: CursorOrder): string {
  const parts = [
    "You received an automated order from a ChatGPT Voice → Cursor bridge.",
    "Implement the task carefully. Prefer minimal, focused changes.",
    "",
    `Task:\n${order.task}`,
  ];
  if (order.doneWhen) {
    parts.push("", `Done when:\n${order.doneWhen}`);
  }
  parts.push(
    "",
    "When finished, summarize what you changed and how to verify it.",
  );
  return parts.join("\n");
}
