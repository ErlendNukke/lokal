import type { Job } from "./types.js";

export class JobStore {
  private jobs: Job[] = [];
  private recentHashes = new Map<string, number>();

  constructor(private dedupMinutes: number) {}

  list(limit = 50): Job[] {
    return this.jobs.slice(0, limit);
  }

  get(id: string): Job | undefined {
    return this.jobs.find((j) => j.id === id);
  }

  isDuplicate(hash: string): boolean {
    this.pruneHashes();
    return this.recentHashes.has(hash);
  }

  rememberHash(hash: string): void {
    this.recentHashes.set(hash, Date.now());
  }

  add(job: Job): Job {
    this.jobs.unshift(job);
    this.rememberHash(job.order.hash);
    if (this.jobs.length > 200) this.jobs.length = 200;
    return job;
  }

  update(id: string, patch: Partial<Job>): Job | undefined {
    const job = this.get(id);
    if (!job) return undefined;
    Object.assign(job, patch, { updatedAt: new Date().toISOString() });
    return job;
  }

  private pruneHashes(): void {
    const cutoff = Date.now() - this.dedupMinutes * 60_000;
    for (const [hash, ts] of this.recentHashes) {
      if (ts < cutoff) this.recentHashes.delete(hash);
    }
  }
}
