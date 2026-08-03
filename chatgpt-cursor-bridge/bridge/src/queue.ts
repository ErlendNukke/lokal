import { randomUUID } from "node:crypto";
import type { BridgeConfig, CursorOrder, Job } from "./types.js";
import { executeOrder } from "./cursorClient.js";
import type { JobStore } from "./store.js";

type Listener = (job: Job) => void;

export class OrderQueue {
  private chain: Promise<void> = Promise.resolve();
  private listeners = new Set<Listener>();

  constructor(
    private config: BridgeConfig,
    private store: JobStore,
  ) {}

  onUpdate(listener: Listener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private emit(job: Job): void {
    for (const listener of this.listeners) listener(job);
  }

  enqueue(order: CursorOrder, source: string): { job: Job; duplicate: boolean } {
    if (this.store.isDuplicate(order.hash)) {
      const skipped: Job = {
        id: randomUUID(),
        order,
        status: "skipped",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        source,
        resultSummary: "Duplicate order ignored (already seen recently).",
      };
      this.store.add(skipped);
      this.emit(skipped);
      return { job: skipped, duplicate: true };
    }

    const job: Job = {
      id: randomUUID(),
      order,
      status: "queued",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      source,
    };
    this.store.add(job);
    this.emit(job);

    this.chain = this.chain.then(() => this.runJob(job.id));
    return { job, duplicate: false };
  }

  private async runJob(id: string): Promise<void> {
    const current = this.store.get(id);
    if (!current || current.status === "skipped") return;

    this.store.update(id, { status: "running" });
    const running = this.store.get(id)!;
    this.emit(running);

    try {
      const result = await executeOrder(this.config, running.order, running);
      const done = this.store.update(id, {
        status: "succeeded",
        agentId: result.agentId,
        runId: result.runId,
        resultSummary: result.summary,
        prUrl: result.prUrl,
      })!;
      this.emit(done);
      console.log(`[bridge] job ${id} succeeded`, result.summary.slice(0, 120));
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      const failed = this.store.update(id, {
        status: "failed",
        error: message,
      })!;
      this.emit(failed);
      console.error(`[bridge] job ${id} failed`, message);
    }
  }
}
