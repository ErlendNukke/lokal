import { defineConfig, devices } from '@playwright/test';

const webPort = process.env.WEB_PORT ?? '4173';
const webUrl = process.env.WEB_URL ?? `http://127.0.0.1:${webPort}`;

export default defineConfig({
  testDir: '.',
  testMatch: 'walkthrough.spec.ts',
  timeout: 480_000,
  expect: { timeout: 30_000 },
  fullyParallel: false,
  workers: 1,
  reporter: [['list']],
  use: {
    baseURL: webUrl,
    trace: 'retain-on-failure',
  },
  projects: [
    {
      name: 'webkit-iphone14',
      use: {
        ...devices['iPhone 14'],
        browserName: 'webkit',
      },
    },
  ],
});
