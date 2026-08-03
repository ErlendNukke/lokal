import type { BridgeConfig, CursorOrder, Job } from "./types.js";
import { buildAgentPrompt } from "./parser.js";

export interface RunResult {
  agentId?: string;
  runId?: string;
  summary: string;
  prUrl?: string;
}

async function cloudCreateAndRun(
  config: BridgeConfig,
  order: CursorOrder,
): Promise<RunResult> {
  const repoUrl = order.repo || config.defaultRepoUrl;
  if (!repoUrl) {
    throw new Error(
      "No repo in order and DEFAULT_REPO_URL is not set. Add `repo: https://github.com/...` to the CURSOR_ORDER.",
    );
  }

  const prompt = buildAgentPrompt(order);
  const auth = Buffer.from(`${config.cursorApiKey}:`).toString("base64");

  const createRes = await fetch("https://api.cursor.com/v1/agents", {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      prompt: { text: prompt },
      model: config.cursorModel,
      repos: [
        {
          url: repoUrl,
          startingRef: order.ref || config.defaultRef,
        },
      ],
      autoCreatePR: config.autoCreatePr,
    }),
  });

  const createBody = (await createRes.json().catch(() => ({}))) as Record<
    string,
    unknown
  >;
  if (!createRes.ok) {
    throw new Error(
      `Cloud Agents API create failed (${createRes.status}): ${JSON.stringify(createBody)}`,
    );
  }

  const agent = (createBody.agent ?? createBody) as Record<string, unknown>;
  const run = (createBody.run ?? {}) as Record<string, unknown>;
  const agentId = String(agent.id ?? createBody.id ?? "");
  const runId = run.id ? String(run.id) : undefined;

  // Poll run status if we have ids; otherwise return create acknowledgement
  if (agentId && runId) {
    const terminal = await pollCloudRun(auth, agentId, runId);
    return {
      agentId,
      runId,
      summary: terminal.summary,
      prUrl: terminal.prUrl,
    };
  }

  return {
    agentId: agentId || undefined,
    runId,
    summary: "Cloud agent created. Open Cursor Agents to follow progress.",
  };
}

async function pollCloudRun(
  auth: string,
  agentId: string,
  runId: string,
  timeoutMs = 25 * 60_000,
): Promise<{ summary: string; prUrl?: string }> {
  const started = Date.now();
  let lastStatus = "unknown";

  while (Date.now() - started < timeoutMs) {
    const res = await fetch(
      `https://api.cursor.com/v1/agents/${agentId}/runs/${runId}`,
      {
        headers: { Authorization: `Basic ${auth}` },
      },
    );
    const body = (await res.json().catch(() => ({}))) as Record<string, unknown>;
    if (!res.ok) {
      throw new Error(
        `Cloud Agents API poll failed (${res.status}): ${JSON.stringify(body)}`,
      );
    }

    const status = String(body.status ?? body.state ?? "unknown").toLowerCase();
    lastStatus = status;

    if (
      ["finished", "completed", "succeeded", "success", "done"].includes(status)
    ) {
      const summary =
        (body.summary as string) ||
        (body.result as string) ||
        "Cloud agent run finished.";
      const prUrl =
        (body.prUrl as string) ||
        ((body.pr as Record<string, unknown> | undefined)?.url as
          | string
          | undefined);
      return { summary, prUrl };
    }

    if (["failed", "error", "cancelled", "canceled"].includes(status)) {
      throw new Error(
        `Cloud agent run ${status}: ${JSON.stringify(body.error ?? body)}`,
      );
    }

    await sleep(5000);
  }

  return {
    summary: `Timed out waiting for run (last status: ${lastStatus}). Agent ${agentId} may still be working in Cursor.`,
  };
}

async function localRun(
  config: BridgeConfig,
  order: CursorOrder,
): Promise<RunResult> {
  // Dynamic import so dry-run/cloud installs don't require local SDK binaries at boot.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let sdk: any;
  try {
    sdk = await import("@cursor/sdk");
  } catch {
    throw new Error(
      "BRIDGE_MODE=local requires `@cursor/sdk`. Run: npm install @cursor/sdk (in bridge/)",
    );
  }
  const agent = await sdk.Agent.create({
    apiKey: config.cursorApiKey!,
    model: { id: config.cursorModel },
    local: { cwd: config.localCwd! },
  });

  try {
    const run = await agent.send(buildAgentPrompt(order));
    let assistant = "";
    for await (const event of run.stream()) {
      if (
        event &&
        typeof event === "object" &&
        "type" in event &&
        (event as { type: string }).type === "assistant" &&
        "message" in event
      ) {
        const message = (event as { message?: { content?: unknown } }).message;
        if (typeof message?.content === "string") assistant += message.content;
      }
    }
    const result = await run.wait();
    return {
      agentId: agent.agentId,
      summary:
        assistant.trim() ||
        (typeof result === "object" && result && "summary" in result
          ? String((result as { summary: unknown }).summary)
          : "Local agent finished."),
    };
  } finally {
    if (typeof agent[Symbol.asyncDispose] === "function") {
      await agent[Symbol.asyncDispose]().catch(() => undefined);
    }
  }
}

export async function executeOrder(
  config: BridgeConfig,
  order: CursorOrder,
  _job: Job,
): Promise<RunResult> {
  if (config.mode === "dry-run") {
    return {
      summary: `[dry-run] Would run on ${order.repo || config.defaultRepoUrl || config.localCwd || "(no repo)"}: ${order.task.slice(0, 160)}`,
    };
  }

  if (config.mode === "cloud") {
    return cloudCreateAndRun(config, order);
  }

  return localRun(config, order);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
