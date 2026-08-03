import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { extractOrders, hashOrder } from "./parser.js";

describe("extractOrders", () => {
  it("parses a basic order block", () => {
    const text = `
Sure — I'll format that for Cursor.

CURSOR_ORDER:
repo: https://github.com/ErlendNukke/lokal
ref: main
task: Add a dark mode toggle on the settings screen.
done when: Toggle persists and works on mobile web.

Anything else?
`;
    const orders = extractOrders(text);
    assert.equal(orders.length, 1);
    assert.equal(orders[0].repo, "https://github.com/ErlendNukke/lokal");
    assert.equal(orders[0].ref, "main");
    assert.match(orders[0].task, /dark mode toggle/i);
    assert.match(orders[0].doneWhen ?? "", /persists/i);
  });

  it("supports fenced blocks and multiline tasks", () => {
    const text = `
\`\`\`cursor_order
CURSOR_ORDER:
task: Fix the login button.
It should show a spinner while loading.
done when: No double submits
\`\`\`
`;
    const orders = extractOrders(text);
    assert.equal(orders.length, 1);
    assert.match(orders[0].task, /spinner/i);
    assert.equal(orders[0].doneWhen, "No double submits");
  });

  it("dedupes identical orders in one scan", () => {
    const block = `
CURSOR_ORDER:
task: Same task twice
`;
    const orders = extractOrders(block + block);
    assert.equal(orders.length, 1);
  });

  it("returns empty when no order marker", () => {
    assert.deepEqual(extractOrders("just chatting about architecture"), []);
  });

  it("hashes are stable", () => {
    assert.equal(hashOrder("Hello  world"), hashOrder("hello world"));
  });
});
