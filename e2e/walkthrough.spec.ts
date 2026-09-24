import { test, expect, type Page } from '@playwright/test';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const ARTIFACTS = process.env.WALKTHROUGH_DIR ?? '/opt/cursor/artifacts/walkthrough';
const PASSWORD = 'password123';
const PRODUCT_FROM_LIISA = 'Käsitsi valmistatud savikauss';
const MARI_BREAD = 'Kodune juuretisleib';

function shotPath(name: string) {
  fs.mkdirSync(ARTIFACTS, { recursive: true });
  return path.join(ARTIFACTS, name);
}

async function screenshot(page: Page, filename: string) {
  await page.screenshot({ path: shotPath(filename), fullPage: true });
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

async function scrollToButton(page: Page, name: string) {
  const btn = page.getByRole('button', { name });
  await btn.scrollIntoViewIfNeeded({ timeout: 30_000 });
  return btn;
}

async function fillField(page: Page, label: string, value: string) {
  const field = page.getByRole('textbox', { name: label, exact: true });
  await field.click({ clickCount: 3 });
  await field.pressSequentially(value, { delay: 5 });
}

async function openAuthFromProfile(page: Page) {
  await tapBottomNav(page, 'Profiil');
  // Visiting Profiil while logged out opens the auth sheet automatically.
  const onAuth = await page.getByRole('button', { name: 'Loo konto' }).isVisible().catch(() => false);
  if (!onAuth) {
    const loginBtn = page.getByRole('button', { name: 'Logi sisse' });
    if (await loginBtn.isVisible().catch(() => false)) {
      await loginBtn.click();
    }
  }
}

async function registerAccount(page: Page, opts: { name: string; email: string; role?: 'Ostja' | 'Tootja' | 'Mõlemad' }) {
  await openAuthFromProfile(page);
  await page.getByRole('button', { name: 'Registreeru' }).click();
  if (opts.role) {
    await page.getByRole('button', { name: new RegExp(`^Roll\\s`) }).click();
    await page.getByRole('menuitem', { name: opts.role }).click({ timeout: 10_000 });
  }
  await fillField(page, 'Nimi', opts.name);
  await fillField(page, 'E-post', opts.email);
  await fillField(page, 'Parool', PASSWORD);
  await Promise.all([
    page.waitForResponse((r) => r.url().includes('/api/auth/register') && r.ok()),
    page.getByRole('button', { name: 'Loo konto' }).click(),
  ]);
  await expect(page.getByRole('button', { name: /^Profiil/ })).toBeVisible({ timeout: 60_000 });
  await tapBottomNav(page, 'Profiil');
  await expect(page.getByRole('button', { name: 'Logi välja' })).toBeVisible({ timeout: 60_000 });
}

async function loginAccount(page: Page, email: string) {
  await openAuthFromProfile(page);
  await page.getByRole('button', { name: 'Sisselogimine' }).click();
  await fillField(page, 'E-post', email);
  await fillField(page, 'Parool', PASSWORD);
  await page.getByRole('button', { name: 'Logi sisse' }).click();
  await expect(page.getByRole('button', { name: /^Profiil/ })).toBeVisible({ timeout: 60_000 });
  await tapBottomNav(page, 'Profiil');
  await expect(page.getByRole('button', { name: 'Logi välja' })).toBeVisible({ timeout: 60_000 });
}

async function logout(page: Page) {
  await tapBottomNav(page, 'Profiil');
  await page.getByRole('button', { name: 'Logi välja' }).click();
  await page.waitForTimeout(800);
}

async function saveProfile(page: Page) {
  const save = page.getByRole('button', { name: 'Salvesta' });
  await Promise.all([
    page.waitForResponse((r) => r.url().includes('/api/auth/me') && r.request().method() === 'PUT' && r.ok()),
    save.click(),
  ]);
  await page.waitForTimeout(500);
}

test.describe('Lokal marketplace walkthrough (iPhone 14 / WebKit)', () => {
  test.use({
    geolocation: { latitude: 59.437, longitude: 24.7536 },
    permissions: ['geolocation'],
    locale: 'et-EE',
  });

  test('signup, producer, browse, orders', async ({ page, context }) => {
    await context.clearCookies();
    await page.goto('/');
    await page.evaluate(() => localStorage.clear());
    await page.reload();
    await waitForApp(page);

    const email = `e2e-${Date.now()}@lokal.test`;
    const productName = `E2E Tomat ${Date.now()}`;

    // (a) Sign up and profile
    await screenshot(page, '01-browse-guest.png');
    await registerAccount(page, { name: 'E2E Kasutaja', email, role: 'Mõlemad' });
    await screenshot(page, '02-signup-landed-profile.png');
    await fillField(page, 'Talu / brändi nimi', 'E2E Talu');
    await saveProfile(page);
    await screenshot(page, '03-profile-producer-role.png');

    await tapBottomNav(page, 'Müü');
    await page.getByRole('button', { name: 'Lisa toode' }).click();
    await screenshot(page, '04-producer-add-form.png');
    await fillField(page, 'Nimi', productName);
    await fillField(page, 'Kirjeldus', 'Automatiseeritud testtoode');
    await fillField(page, 'Hind (€)', '3.50');
    await fillField(page, 'Kogus', '5');

    const fileChooserPromise = page.waitForEvent('filechooser');
    await page.getByRole('button', { name: 'Lisa foto' }).click();
    const chooser = await fileChooserPromise;
    await chooser.setFiles(path.join(__dirname, 'fixtures', 'test-product.png'));
    await expect(page.getByRole('button', { name: 'Foto valitud' })).toBeVisible({ timeout: 30_000 });
    await screenshot(page, '05-producer-photo-selected.png');
    const saveProduct = await scrollToButton(page, 'Salvesta toode');
    await expect(saveProduct).toBeEnabled({ timeout: 30_000 });
    await Promise.all([
      page.waitForResponse(
        (r) => r.url().includes('/api/producer/products') && r.request().method() === 'POST' && r.ok(),
      ),
      saveProduct.click(),
    ]);
    await expect(page.getByText(productName)).toBeVisible({ timeout: 60_000 });
    await screenshot(page, '06-producer-product-listed.png');

    await tapBottomNav(page, 'Avasta');
    await expect(page.getByRole('button', { name: productName })).toBeVisible({ timeout: 60_000 });
    await screenshot(page, '07-browse-new-product-on-map-list.png');

    // (c) Browse product detail
    await page.getByRole('button', { name: productName }).click();
    await expect(page.getByText('Telli', { exact: true })).toBeVisible();
    await screenshot(page, '08-product-detail.png');
    await page.goBack();
    await waitForApp(page);

    // (d) Mari orders from another producer (Liisa, Tallinn)
    await logout(page);
    await loginAccount(page, 'mari@lokal.app');
    await tapBottomNav(page, 'Avasta');
    await expect(page.getByRole('button', { name: PRODUCT_FROM_LIISA })).toBeVisible({ timeout: 60_000 });
    await screenshot(page, '09-browse-as-mari.png');
    await page.getByRole('button', { name: PRODUCT_FROM_LIISA }).click();
    await fillField(page, 'Kogus', '1');
    await fillField(page, 'Sõnum tootjale', 'E2E tellimus');
    await screenshot(page, '10-order-form.png');
    await page.getByRole('button', { name: 'Telli' }).click();
    await expect(page.getByText('Tellimus saadetud tootjale')).toBeVisible({ timeout: 30_000 });
    await screenshot(page, '11-order-confirmation-snackbar.png');

    await tapBottomNav(page, 'Tellimused');
    await expect(page.getByText('Tasumine kohapeal')).toBeVisible();
    await expect(page.getByText('Ootel')).toBeVisible();
    await screenshot(page, '12-orders-buyer-pending.png');

    // Two pending orders on Mari’s products (from e2e user + Anna) for accept/decline.
    await logout(page);
    await loginAccount(page, email);
    await tapBottomNav(page, 'Avasta');
    await page.getByRole('button', { name: MARI_BREAD }).click();
    await page.getByRole('button', { name: 'Telli' }).click();
    await expect(page.getByText('Tellimus saadetud tootjale')).toBeVisible({ timeout: 30_000 });

    await logout(page);
    await loginAccount(page, 'anna@lokal.app');
    await tapBottomNav(page, 'Avasta');
    await page.getByRole('button', { name: MARI_BREAD }).click();
    await page.getByRole('button', { name: 'Telli' }).click();
    await expect(page.getByText('Tellimus saadetud tootjale')).toBeVisible({ timeout: 30_000 });

    // (e) Mari as producer: accept one, decline another
    await logout(page);
    await loginAccount(page, 'mari@lokal.app');
    await tapBottomNav(page, 'Tellimused');
    await page.getByRole('button', { name: /^Müün/ }).click();
    await screenshot(page, '13-orders-seller-inbox.png');
    const acceptButtons = page.getByRole('button', { name: 'Võta vastu' });
    const declineButtons = page.getByRole('button', { name: 'Keeldu' });
    await expect(acceptButtons.first()).toBeVisible();
    await declineButtons.first().click();
    await page.waitForTimeout(1000);
    await acceptButtons.first().click();
    await page.waitForTimeout(1000);
    await screenshot(page, '14-orders-seller-after-actions.png');

    // Buyer sees updated status on the accepted order
    await logout(page);
    await loginAccount(page, email);
    await tapBottomNav(page, 'Tellimused');
    await expect(page.getByText('Kinnitatud').or(page.getByText('Tagasi lükatud'))).toBeVisible();
    await screenshot(page, '15-buyer-sees-updated-status.png');

    // Mari cancels a pending order as buyer
    await logout(page);
    await loginAccount(page, 'mari@lokal.app');
    await tapBottomNav(page, 'Tellimused');
    const cancelBtn = page.getByRole('button', { name: 'Tühista' }).first();
    if (await cancelBtn.isVisible().catch(() => false)) {
      await cancelBtn.click();
      await page.waitForTimeout(1000);
      await expect(page.getByText('Tühistatud')).toBeVisible();
      await screenshot(page, '16-buyer-cancelled-order.png');
    } else {
      // Place another order to cancel
      await tapBottomNav(page, 'Avasta');
      await page.getByRole('button', { name: PRODUCT_FROM_LIISA }).click();
      await page.getByRole('button', { name: 'Telli' }).click();
      await tapBottomNav(page, 'Tellimused');
      await page.getByRole('button', { name: 'Tühista' }).first().click();
      await expect(page.getByText('Tühistatud')).toBeVisible();
      await screenshot(page, '16-buyer-cancelled-order.png');
    }
  });
});
