import { test, expect, type Page } from '@playwright/test';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const ARTIFACTS =
  process.env.CATEGORY_CHIPS_DIR ?? path.join(__dirname, '..', 'artifacts', 'screenshots');

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

test.describe('Category filter chips (WebKit)', () => {
  test.use({
    geolocation: { latitude: 59.437, longitude: 24.7536 },
    permissions: ['geolocation'],
    locale: 'et-EE',
  });

  for (const width of [375, 390]) {
    test(`browse chips at ${width}px`, async ({ page }) => {
      await page.setViewportSize({ width, height: 844 });
      await page.goto('/');
      await waitForApp(page);
      await expect(page.getByRole('button', { name: /^Avasta/ })).toBeVisible({ timeout: 180_000 });
      await expect(page.locator('body')).toContainText(/\d+ toodet/, { timeout: 120_000 });
      await expect(page.getByRole('button', { name: 'Kõik' })).toBeVisible();
      await expect(page.getByRole('button', { name: 'Toit' })).toBeVisible();
      await expect(page.getByRole('button', { name: 'Talutooted' })).toBeVisible();

      const suffix = process.env.CHIP_SCREENSHOT_SUFFIX ?? 'after';
      await page.screenshot({
        path: shotPath(`browse-category-chips-${width}-${suffix}.png`),
        fullPage: false,
        clip: { x: 0, y: 0, width, height: 280 },
      });
    });
  }
});
