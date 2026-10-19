# Visual audit artifacts (WebKit / iPhone viewport)

Playwright screenshots from the light-theme polish pass.

## Category filter chips (375px / 390px)

- **Before** (teal primary leftover from #27): `screenshots/browse-category-chips-*-before.png`
- **After** (icon red `#D9381E`, black wordmark): `screenshots/browse-category-chips-*-after.png`

Captured via `e2e/run-category-chips-screenshots.sh` (`playwright.category-chips.config.ts`).

## Full marketplace walkthrough

Release build with `ENABLE_SEMANTICS=true`, iPhone 14 WebKit — `walkthrough-after/` (16 screens, same flow as `e2e/walkthrough.spec.ts`).
