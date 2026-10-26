import { test, expect, type Page } from '@playwright/test';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const ARTIFACTS = process.env.ACCOUNT_DELETION_SCREENSHOT_DIR ?? '/opt/cursor/artifacts/account-deletion';
const PASSWORD = 'password123';

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

async function tapBottomNav(page: Page, label: string) {
  const nav = page.getByRole('button', { name: new RegExp(`^${label}`) });
  await expect(nav).toBeVisible({ timeout: 60_000 });
  await nav.click();
  await page.waitForTimeout(600);
}

async function fillField(page: Page, label: string, value: string) {
  const field = page.getByRole('textbox', { name: label, exact: true });
  await field.click();
  await field.pressSequentially(value, { delay: 10 });
}

test.describe('Account deletion UI (iPhone 14 / WebKit)', () => {
  test.use({
    geolocation: { latitude: 59.437, longitude: 24.7536 },
    permissions: ['geolocation'],
    locale: 'et-EE',
  });

  test('profile delete action and confirmation dialog', async ({ page, context }) => {
    await context.clearCookies();
    await page.goto('/');
    await page.evaluate(() => localStorage.clear());
    await page.reload();
    await waitForApp(page);

    const email = `delete-ui-${Date.now()}@lokal.test`;

    await tapBottomNav(page, 'Profiil');
    await page.getByRole('button', { name: 'Logi sisse' }).click();
    await page.getByRole('button', { name: 'Registreeru', exact: true }).click();
    await fillField(page, 'Nimi', 'Kustuta UI');
    await fillField(page, 'E-post', email);
    await fillField(page, 'Parool', PASSWORD);
    await Promise.all([
      page.waitForResponse((r) => r.url().includes('/api/auth/register') && r.ok(), { timeout: 60_000 }),
      page.getByRole('button', { name: 'Loo konto' }).click(),
    ]);
    await tapBottomNav(page, 'Profiil');
    await expect(page.getByRole('button', { name: 'Kustuta konto' })).toBeVisible({ timeout: 60_000 });
    await page.screenshot({ path: shotPath('profile-delete-account-action.png'), fullPage: true });

    await page.getByRole('button', { name: 'Kustuta konto' }).click();
    await expect(page.getByText('Kustuta konto?', { exact: true })).toBeVisible({ timeout: 30_000 });
    await page.waitForTimeout(400);
    await page.screenshot({ path: shotPath('profile-delete-account-dialog.png'), fullPage: true });
  });
});
