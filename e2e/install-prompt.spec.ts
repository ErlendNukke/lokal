import { test, expect, type Page } from '@playwright/test';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const ARTIFACTS =
  process.env.INSTALL_PROMPT_DIR ?? '/opt/cursor/artifacts/install-prompt';

function shotPath(name: string) {
  fs.mkdirSync(ARTIFACTS, { recursive: true });
  return path.join(ARTIFACTS, name);
}

async function waitForApp(page: Page) {
  await page.waitForFunction(
    () => document.querySelector('flt-glass-pane') != null || document.querySelector('flutter-view') != null,
    { timeout: 120_000 },
  );
  await page.waitForTimeout(2000);
}

test.describe('Add-to-home-screen prompt (iPhone 14 / WebKit)', () => {
  test.use({
    geolocation: { latitude: 59.437, longitude: 24.7536 },
    permissions: ['geolocation'],
    locale: 'et-EE',
  });

  test('iOS hint, dismiss, and browse unchanged', async ({ page }) => {
    await page.goto('/');
    await waitForApp(page);
    await expect(page.getByRole('button', { name: /^Avasta/ })).toBeVisible({ timeout: 180_000 });

    await expect(page.getByLabel('Lisa Lokal avaekraanile: kasuta Jagamise menüüd')).toBeVisible({
      timeout: 30_000,
    });
    await page.screenshot({ path: shotPath('01-ios-install-hint.png'), fullPage: true });

    await page.getByRole('button', { name: /Peida/ }).click();
    await expect(page.getByLabel('Lisa Lokal avaekraanile: kasuta Jagamise menüüd')).toBeHidden({
      timeout: 10_000,
    });
    await page.screenshot({ path: shotPath('02-hint-dismissed.png'), fullPage: true });

    await expect(page.getByRole('button', { name: /^Avasta/ })).toBeVisible();
    await expect(page.locator('body')).toContainText(/\d+ toodet/, { timeout: 120_000 });
    await page.screenshot({ path: shotPath('03-browse-unchanged.png'), fullPage: true });
  });
});
