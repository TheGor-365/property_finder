// Real Chromium checks and image evidence, only against ephemeral Actions DB.
// Never print credentials or upload the local credential JSON as an artifact.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const { chromium } = require(path.resolve("tmp/browser_qa/node_modules/playwright"));
const credentials = JSON.parse(fs.readFileSync("tmp/browser_qa/credentials.json", "utf8"));
const output = path.resolve("tmp/browser_qa/screenshots");
const origin = "http://127.0.0.1:3000";
fs.mkdirSync(output, { recursive: true });

const errors = [];
const screenshots = [];
const capture = async (page, filename) => {
  await page.screenshot({ path: path.join(output, filename), fullPage: true });
  screenshots.push(filename);
};
const goto = async (page, route) => {
  const response = await page.goto(origin + route, { waitUntil: "networkidle" });
  assert.equal(response.status(), 200, `Unexpected HTTP ${response.status()}: ${route}`);
};
const checkNoOverflow = async (page, label) => {
  const metrics = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    scroll: document.documentElement.scrollWidth
  }));
  assert.ok(metrics.scroll <= metrics.viewport + 3,
    `Horizontal overflow ${label}: ${JSON.stringify(metrics)}`);
};

(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const mobile = await browser.newContext({
      viewport: { width: 390, height: 844 }, deviceScaleFactor: 1,
      isMobile: true, hasTouch: true
    });
    const page = await mobile.newPage();
    page.on("pageerror", error => errors.push(error.message));
    await goto(page, "/");
    await checkNoOverflow(page, "mobile home");
    const gap = await page.evaluate(() => {
      const nav = document.querySelector(".pf-public-header").getBoundingClientRect();
      const hero = document.querySelector(".pf-home-hero").getBoundingClientRect();
      return Math.abs(hero.top - nav.bottom);
    });
    assert.ok(gap <= 2, `Unexpected gap under public navbar: ${gap}px`);

    const toggle = page.getByRole("button", { name: "Toggle navigation" });
    assert.equal(await toggle.isVisible(), true, "Mobile navigation toggle missing");
    await toggle.click();
    await page.locator("#navbarsExampleDefault").waitFor({ state: "visible" });
    assert.equal(await page.locator("#navbarsExampleDefault").getByRole("link",
      { name: "Properties" }).isVisible(), true);
    await capture(page, "01-mobile-navigation-open.png");

    await goto(page, "/properties");
    await checkNoOverflow(page, "mobile catalogue");
    assert.equal(await page.getByRole("heading",
      { name: "Browse available properties" }).isVisible(), true);
    await capture(page, "02-mobile-catalogue.png");

    await goto(page, `/properties/${credentials.property_id}`);
    await checkNoOverflow(page, "mobile detail");
    await page.getByRole("button", { name: "Contact listing agent" }).click();
    await page.locator("#contact-modal").waitFor({ state: "visible" });
    await capture(page, "03-mobile-enquiry-modal.png");
    await page.locator('#contact-modal input[name="enquiry[name]"]').fill("Browser QA Visitor");
    await page.locator('#contact-modal input[name="enquiry[email]"]').fill("browser-qa-visitor@example.invalid");
    await page.locator('#contact-modal textarea[name="enquiry[message]"]')
      .fill("I would like to arrange a demonstration viewing of this fictional home.");
    await page.locator("#contact-modal").getByRole("button", { name: "Send enquiry" }).click();
    await page.waitForURL(`**/properties/${credentials.property_id}`);
    assert.equal(await page.getByText("Enquiry received.", { exact: false }).isVisible(), true);
    await capture(page, "04-mobile-enquiry-confirmation.png");

    await goto(page, "/accounts/sign_in");
    await page.locator('input[name="account[email]"]').fill(credentials.email);
    await page.locator('input[name="account[password]"]').fill(credentials.password);
    await page.getByRole("button", { name: /Sign in/i }).click();
    await goto(page, "/dashboard");
    await checkNoOverflow(page, "mobile workspace");
    const sidebarToggle = page.getByRole("button", { name: "Toggle navigation" });
    await sidebarToggle.click();
    await page.locator("#sidebarMenu").waitFor({ state: "visible" });
    await capture(page, "05-mobile-agent-workspace.png");

    await goto(page, "/enquiries");
    await checkNoOverflow(page, "mobile inbox");
    const row = page.locator('article[id^="enquiry-"]').filter({ hasText: "Browser QA Visitor" });
    assert.equal(await row.count(), 1, "Saved enquiry missing from private inbox");
    await row.locator('select[name="enquiry[status]"]').selectOption("contacted");
    await row.getByRole("button", { name: "Update" }).click();
    await goto(page, "/enquiries");
    const persisted = page.locator('article[id^="enquiry-"]').filter({ hasText: "Browser QA Visitor" });
    assert.equal(await persisted.locator('select[name="enquiry[status]"]').inputValue(), "contacted");
    await capture(page, "06-mobile-agent-inbox.png");

    const desktop = await browser.newContext({
      viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1
    });
    const publicPage = await desktop.newPage();
    publicPage.on("pageerror", error => errors.push(error.message));
    for (const [route, name] of [
      ["/", "07-desktop-home.png"],
      ["/properties", "08-desktop-catalogue.png"],
      [`/properties/${credentials.property_id}`, "09-desktop-detail.png"],
      [`/profile/${credentials.agent_id}`, "10-desktop-agent-profile.png"],
      ["/blog", "11-desktop-journal.png"]
    ]) {
      await goto(publicPage, route);
      await checkNoOverflow(publicPage, route);
      await capture(publicPage, name);
    }

    assert.deepEqual(errors, [], "Uncaught page JavaScript errors");
    console.log("BROWSER_QA=PASS");
    console.log("SCREENSHOTS=" + screenshots.length);
    console.log("MOBILE_NAVBAR_GAP_PX=" + gap);
    console.log("ENQUIRY_PERSISTENCE=PASS");
    console.log("AGENT_STATUS_RELOAD=PASS");
  } finally {
    await browser.close();
  }
})().catch(error => {
  console.error("BROWSER_QA=FAIL");
  console.error(error.stack || String(error));
  process.exitCode = 1;
});
