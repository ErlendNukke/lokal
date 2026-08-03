export type BridgeMode = "cloud" | "local" | "dry-run";

export type JobStatus =
  | "queued"
  | "running"
  | "succeeded"
  | "failed"
  | "skipped";

export interface CursorOrder {
  raw: string;
  task: string;
  repo?: string;
  ref?: string;
  doneWhen?: string;
  hash: string;
}

export interface Job {
  id: string;
  order: CursorOrder;
  status: JobStatus;
  createdAt: string;
  updatedAt: string;
  source: string;
  agentId?: string;
  runId?: string;
  resultSummary?: string;
  error?: string;
  prUrl?: string;
}

export interface BridgeConfig {
  mode: BridgeMode;
  port: number;
  host: string;
  bridgeToken: string;
  cursorApiKey?: string;
  defaultRepoUrl?: string;
  defaultRef: string;
  autoCreatePr: boolean;
  cursorModel: string;
  localCwd?: string;
  dedupMinutes: number;
}
