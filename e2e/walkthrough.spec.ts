import { test, expect, type Page, type APIRequestContext } from '@playwright/test';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const ARTIFACTS = process.env.WALKTHROUGH_DIR ?? '/opt/cursor/artifacts/walkthrough';
const API_BASE = process.env.API_BASE_URL ?? 'http://localhost:8080';
const PASSWORD = 'password123';
const MARI_BREAD = 'Kodune juuretisleib';

function shotPath(name: string) {
  fs.mkdirSync(ARTIFACTS, { recursive: true });
  return path.join(ARTIFACTS, name);
}

async function screenshot(page: Page, filename: string) {
  await page.screenshot({ path: shotPath(filename), fullPage: true });
}

async function firstProductName(request: APIRequestContext): Promise<string> {
  const res = await request.get(`${API_BASE}/api/products`, {
    params: { lat: '59.437', lng: '24.7536', radiusKm: '10' },
  });
  expect(res.ok()).toBeTruthy();
  const products = (await res.json()) as { name: string }[];
  const pick =
    products.find((p) => p.name.includes('Tomatitaimed')) ??
    products.find((p) => p.name.includes('Mahepõllumajanduslikud')) ??
    products.find((p) => !p.name.startsWith('E2E')) ??
    products[0];
  if (!pick) throw new Error('No products in seed/API');
  return pick.name;
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

async function openProductFromBrowse(page: Page, productName: string) {
  await tapBottomNav(page, 'Avasta');
  await expect(page.getByRole('button', { name: /^Avasta/ })).toBeVisible({ timeout: 60_000 });
  await expect(page.locator('body')).toContainText(/\d+ toodet/, { timeout: 120_000 });
  const search = page.getByRole('textbox', { name: 'Otsi maasikaid, mett, leiba…' });
  await search.click();
  await search.pressSequentially(productName.slice(0, 16), { delay: 10 });
  await Promise.all([
    page.waitForResponse(
      (r) => r.url().includes('/api/products') && r.request().method() === 'GET' && r.ok(),
      { timeout: 90_000 },
    ),
    search.press('Enter'),
  ]);
  const card = page.getByRole('button', { name: new RegExp(productName.slice(0, 10)) });
  await expect(card).toBeVisible({ timeout: 60_000 });
  await card.click();
}

async function dismissKeyboard(page: Page) {
  await page.getByRole('heading', { name: 'Müüja töölaud' }).click({ force: true }).catch(() => {});
  await page.waitForTimeout(250);
}

async function revealSaveProduct(page: Page) {
  await dismissKeyboard(page);
  const appBarSave = page.getByRole('button', { name: 'Salvesta toode' }).first();
  if (await appBarSave.isVisible().catch(() => false)) {
    return appBarSave;
  }
  const btn = page.getByRole('button', { name: 'Salvesta toode' }).last();
  await btn.scrollIntoViewIfNeeded({ timeout: 15_000 }).catch(() => {});
  return btn;
}

async function fillField(page: Page, label: string, value: string) {
  const field = page.getByRole('textbox', { name: label, exact: true });
  await field.click();
  // WebKit + Flutter web: use sequential key events (fill()/triple-click break email + TextEditingController sync).
  await field.pressSequentially(value, { delay: 10 });
}

async function clickOrderSubmit(page: Page) {
  const telli = page.getByRole('button', { name: 'Telli', exact: true });
  await telli.scrollIntoViewIfNeeded();
  await telli.click();
}

async function leaveProductDetail(page: Page) {
  const back = page.getByRole('button', { name: /^(Tagasi|Back)$/ });
  if (await back.isVisible().catch(() => false)) {
    await back.click();
  } else {
    await page.goBack();
  }
  await page.waitForTimeout(500);
}

async function openAuthFromProfile(page: Page) {
  await tapBottomNav(page, 'Profiil');
  const onRegisterForm = await page.getByRole('button', { name: 'Loo konto' }).isVisible().catch(() => false);
  if (onRegisterForm) return;
  const profileLogin = page.getByRole('button', { name: 'Logi sisse' }).first();
  if (await profileLogin.isVisible().catch(() => false)) {
    await profileLogin.click();
  }
}

async function registerAccount(page: Page, opts: { name: string; email: string; role?: 'Ostja' | 'Tootja' | 'Mõlemad' }) {
  for (let attempt = 0; attempt < 3; attempt++) {
    await openAuthFromProfile(page);
    const onRegisterForm = await page.getByRole('button', { name: 'Loo konto' }).isVisible().catch(() => false);
    if (onRegisterForm) break;
    const regTab = page.getByRole('button', { name: 'Registreeru' });
    if (await regTab.isVisible().catch(() => false)) {
      await regTab.click();
      break;
    }
    await page.waitForTimeout(2000);
    await page.reload({ waitUntil: 'load' });
    await waitForApp(page);
  }
  await expect(page.getByRole('button', { name: 'Loo konto' })).toBeVisible({ timeout: 120_000 });
  if (opts.role) {
    await page.getByRole('button', { name: new RegExp(`^Roll\\s`) }).click();
    await page.getByRole('menuitem', { name: opts.role }).click({ timeout: 10_000 });
  }
  await fillField(page, 'Nimi', opts.name);
  await fillField(page, 'E-post', opts.email);
  await fillField(page, 'Parool', PASSWORD);
  await Promise.all([
    page.waitForResponse((r) => r.url().includes('/api/auth/register') && r.ok(), { timeout: 60_000 }),
    page.getByRole('button', { name: 'Loo konto' }).click(),
  ]);
  await expect(
    page.getByRole('button', { name: /^Profiil/ }).or(page.getByRole('button', { name: /^Müü/ })),
  ).toBeVisible({ timeout: 60_000 });
  await tapBottomNav(page, 'Profiil');
  await expect(page.getByRole('button', { name: 'Logi välja' })).toBeVisible({ timeout: 60_000 });
}

async function loginAccount(page: Page, _request: APIRequestContext, email: string) {
  const demoChip =
    email === 'mari@lokal.app'
      ? 'Tootja · Mari'
      : email === 'anna@lokal.app'
        ? 'Ostja · Anna'
        : null;
  expect(demoChip, `Demo login chip missing for ${email}`).toBeTruthy();

  await page.evaluate(() => localStorage.clear());
  await page.goto('/', { waitUntil: 'load' });
  await waitForApp(page);
  await expect(page.getByRole('button', { name: /^Avasta/ })).toBeVisible({ timeout: 120_000 });
  await tapBottomNav(page, 'Profiil');
  await page.getByRole('button', { name: demoChip! }).click();
  await Promise.all([
    page.waitForResponse((r) => r.url().includes('/api/auth/login') && r.ok(), { timeout: 60_000 }),
    page.getByRole('button', { name: 'Logi sisse' }).last().click(),
  ]);

  await expect(page.getByRole('button', { name: /^Profiil/ })).toBeVisible({ timeout: 60_000 });
  await tapBottomNav(page, 'Profiil');
  await expect(page.getByRole('button', { name: 'Logi välja' })).toBeVisible({ timeout: 60_000 });
}

async function logout(page: Page) {
  await tapBottomNav(page, 'Profiil');
  await page.getByRole('button', { name: 'Logi välja' }).click();
  await page.waitForTimeout(500);
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

  test('signup, producer, browse, orders', async ({ page, context, request }) => {
    await context.clearCookies();
    await page.goto('/');
    await page.evaluate(async () => {
      localStorage.clear();
      const regs = await navigator.serviceWorker?.getRegistrations?.();
      for (const r of regs ?? []) await r.unregister();
    });
    await page.reload();
    await waitForApp(page);
    await expect(page.getByRole('button', { name: /^Avasta/ })).toBeVisible({ timeout: 180_000 });
    await page
      .waitForResponse((r) => r.url().includes('/api/products') && r.request().method() === 'GET' && r.ok(), {
        timeout: 120_000,
      })
      .catch(() => {});

    const email = `e2e-${Date.now()}@lokal.test`;
    const productName = `E2E Tomat ${Date.now()}`;

    // (a) Sign up and profile (before guest browse so CI has time budget for the full flow)
    await registerAccount(page, { name: 'E2E Kasutaja', email });
    await screenshot(page, '02-signup-landed-profile.png');
    await page.getByRole('button', { name: /^Roll/ }).click();
    await page.getByRole('menuitem', { name: 'Mõlemad' }).click();
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
    await page.getByRole('textbox', { name: 'Nimi', exact: true }).press('Tab');
    await page.waitForTimeout(300);

    const fileChooserPromise = page.waitForEvent('filechooser');
    await page.getByRole('button', { name: 'Lisa foto' }).click();
    const chooser = await fileChooserPromise;
    await chooser.setFiles(path.join(__dirname, 'fixtures', 'test-product.png'));
    await expect(page.getByRole('button', { name: 'Foto valitud' })).toBeVisible({ timeout: 30_000 });
    await screenshot(page, '05-producer-photo-selected.png');
    const saveProduct = await revealSaveProduct(page);
    await expect(saveProduct).toBeEnabled({ timeout: 30_000 });
    test.info().annotations.push({
      type: 'note',
      description:
        'Salvesta toode on WebKit: harness artifact (triple-click/fill() desync Flutter text fields); click + pressSequentially + app-bar save POSTs /api/producer/products (not an app bug).',
    });
    await Promise.all([
      page.waitForResponse(
        (r) =>
          r.url().includes('/api/producer/products') &&
          r.request().method() === 'POST' &&
          r.ok(),
        { timeout: 60_000 },
      ),
      saveProduct.click(),
    ]);
    await page.waitForResponse(
      (r) => r.url().includes('/api/producer/products') && r.request().method() === 'GET' && r.ok(),
      { timeout: 60_000 },
    );
    await expect(page.getByRole('button', { name: 'Sulge' })).toBeHidden({ timeout: 30_000 });
    await screenshot(page, '06-producer-product-listed.png');

    // (c) Browse Avasta as guest (map + list + detail)
    await logout(page);
    await page.goto('/', { waitUntil: 'load' });
    await waitForApp(page);
    await screenshot(page, '01-browse-guest.png');
    await expect(page.locator('body')).toContainText(/\d+ toodet/, { timeout: 120_000 });
    await screenshot(page, '07-browse-map-and-list.png');
    const productNameOnMap = await firstProductName(request);
    const search = page.getByRole('textbox', { name: 'Otsi maasikaid, mett, leiba…' });
    await search.click();
    await search.pressSequentially(productNameOnMap.slice(0, 12), { delay: 10 });
    await Promise.all([
      page.waitForResponse(
        (r) => r.url().includes('/api/products') && r.request().method() === 'GET' && r.ok(),
        { timeout: 90_000 },
      ),
      search.press('Enter'),
    ]);
    const guestProduct = page.getByRole('button', { name: new RegExp(productNameOnMap.slice(0, 8)) });
    await expect(guestProduct).toBeVisible({ timeout: 90_000 });
    await guestProduct.click();
    await expect(page.getByText('Telli', { exact: true })).toBeVisible();
    await screenshot(page, '08-product-detail.png');

    // (d) Anna (buyer-only) orders from Mari — primary customer flow
    await page.goto('/', { waitUntil: 'load' });
    await waitForApp(page);
    await loginAccount(page, request, 'anna@lokal.app');
    await openProductFromBrowse(page, MARI_BREAD);
    await screenshot(page, '09-browse-as-anna.png');
    await fillField(page, 'Sõnum tootjale', 'E2E tellimus');
    await screenshot(page, '10-order-form.png');
    await Promise.all([
      page.waitForResponse(
        (r) => r.url().includes('/api/orders') && r.request().method() === 'POST' && r.ok(),
        { timeout: 60_000 },
      ),
      clickOrderSubmit(page),
    ]);
    await expect(page.getByRole('button', { name: /^Avasta/ })).toBeVisible({ timeout: 60_000 });
    await screenshot(page, '11-order-confirmation-snackbar.png');

    await tapBottomNav(page, 'Tellimused');
    await expect(page.getByRole('button', { name: 'Tühista' }).first()).toBeVisible({ timeout: 60_000 });
    await expect(page.getByLabel(/Tasumine kohapeal/).first()).toBeVisible();
    await expect(page.locator('body')).toContainText('Ootel');
    await screenshot(page, '12-orders-buyer-pending.png');

    // Second pending order on Mari’s bread (UI) for seller accept/decline
    await page.goto('/', { waitUntil: 'load' });
    await waitForApp(page);
    await openProductFromBrowse(page, MARI_BREAD);
    await Promise.all([
      page.waitForResponse(
        (r) => r.url().includes('/api/orders') && r.request().method() === 'POST' && r.ok(),
        { timeout: 60_000 },
      ),
      clickOrderSubmit(page),
    ]);
    await expect(page.getByRole('button', { name: /^Avasta/ })).toBeVisible({ timeout: 60_000 });

    // (e) Mari as producer: accept one, decline another
    await logout(page);
    await loginAccount(page, request, 'mari@lokal.app');
    await tapBottomNav(page, 'Tellimused');
    await page.getByRole('button', { name: 'Müün', exact: true }).click();
    await screenshot(page, '13-orders-seller-inbox.png');
    const acceptButtons = page.getByRole('button', { name: 'Võta vastu' });
    const declineButtons = page.getByRole('button', { name: 'Keeldu' });
    await expect(acceptButtons.first()).toBeVisible();
    await declineButtons.first().click();
    await page.waitForTimeout(1000);
    await acceptButtons.first().click();
    await page.waitForTimeout(1000);
    await screenshot(page, '14-orders-seller-after-actions.png');

    // Buyer (Anna) sees updated status on her orders
    await logout(page);
    await loginAccount(page, request, 'anna@lokal.app');
    await tapBottomNav(page, 'Tellimused');
    await expect(page.getByText('Kinnitatud').or(page.getByText('Tagasi lükatud')).first()).toBeVisible({
      timeout: 60_000,
    });
    await screenshot(page, '15-buyer-sees-updated-status.png');

    // Anna cancels a pending order (buyer-only customer flow)
    await page.goto('/', { waitUntil: 'load' });
    await waitForApp(page);
    await openProductFromBrowse(page, MARI_BREAD);
    await Promise.all([
      page.waitForResponse(
        (r) => r.url().includes('/api/orders') && r.request().method() === 'POST' && r.ok(),
        { timeout: 60_000 },
      ),
      clickOrderSubmit(page),
    ]);
    await tapBottomNav(page, 'Tellimused');
    await page.getByRole('button', { name: 'Tühista' }).first().click();
    await page.waitForTimeout(1000);
    await expect(page.getByText('Tühistatud').first()).toBeVisible({ timeout: 60_000 });
    await screenshot(page, '16-buyer-cancelled-order.png');
  });
});
