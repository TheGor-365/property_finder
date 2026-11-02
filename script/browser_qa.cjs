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
  const viewportOnly = /^(01-|03-|04-mobile-enquiry-validation|05-)/.test(filename);
  await page.screenshot({ path: path.join(output, filename), fullPage: !viewportOnly });
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
      isMobile: true, hasTouch: true,
      // Browser-native video proof on fictional CI fixtures only.
      recordVideo: {
        dir: "tmp/browser_qa/video",
        size: { width: 390, height: 844 }
      }
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
    await page.locator("#navbarsExampleDefault.show").waitFor({ state: "visible" });
    assert.equal(await page.locator("#navbarsExampleDefault").getByRole("link",
      { name: "Properties" }).isVisible(), true);
    const expandedNavHeight = await page.locator("#navbarsExampleDefault")
      .evaluate(element => element.getBoundingClientRect().height);
    assert.ok(expandedNavHeight > 80,
      `Navigation was not fully expanded: ${expandedNavHeight}px`);
    await capture(page, "01-mobile-navigation-open.png");

    await goto(page, "/properties");
    await checkNoOverflow(page, "mobile catalogue");
    assert.equal(await page.getByRole("heading",
      { name: "Browse available properties" }).isVisible(), true);
    await capture(page, "02-mobile-catalogue.png");

    await goto(page, `/properties/${credentials.property_id}`);
    await checkNoOverflow(page, "mobile detail");
    await page.getByRole("button", { name: "Contact listing agent" }).click();
    await page.locator("#contact-modal.show").waitFor({ state: "visible" });
    await page.waitForTimeout(350); // Bootstrap modal fade transition
    await capture(page, "03-mobile-enquiry-modal.png");
    await page.locator('#contact-modal input[name="enquiry[name]"]').fill("Browser QA Visitor");

    // Verify the server-side 422 and preserved fields in an actual browser,
    // bypassing HTML5 validation only for this deliberate negative test.
    await page.locator('#contact-modal input[name="enquiry[email]"]').fill("not-an-email");
    await page.locator('#contact-modal textarea[name="enquiry[message]"]').fill("short");
    await page.locator('form#email_agent').evaluate(form => { form.noValidate = true; });
    const [invalidResponse] = await Promise.all([
      page.waitForResponse(response => response.url().endsWith("/enquiries") &&
        response.request().method() === "POST"),
      page.locator("#contact-modal").getByRole("button", { name: "Send enquiry" }).click()
    ]);
    assert.equal(invalidResponse.status(), 422, "Invalid enquiry must return HTTP 422");
    await page.locator("#contact-modal.show").waitFor({ state: "visible" });
    assert.equal(await page.locator('#contact-modal input[name="enquiry[name]"]').inputValue(),
      "Browser QA Visitor");
    assert.equal(await page.locator('#contact-modal input[name="enquiry[email]"]').inputValue(),
      "not-an-email");
    assert.equal(await page.locator("#contact-modal .alert-danger").isVisible(), true);
    await page.waitForTimeout(350); // Bootstrap modal fade transition
    await capture(page, "04-mobile-enquiry-validation.png");

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
    await page.locator("#sidebarMenu.show").waitFor({ state: "visible" });
    assert.equal(await page.locator("#sidebarMenu").getByRole("link",
      { name: "Enquiries" }).isVisible(), true);
    const sidebarSize = await page.locator("#sidebarMenu").evaluate(element => {
      const r = element.getBoundingClientRect();
      return { top: r.top, bottom: r.bottom, height: r.height };
    });
    assert.ok(sidebarSize.height >= 180 && sidebarSize.height <= 520,
      `Mobile sidebar has excessive height: ${JSON.stringify(sidebarSize)}`);
    assert.ok(sidebarSize.bottom < 844,
      `Mobile sidebar unnecessarily fills the screen: ${JSON.stringify(sidebarSize)}`);
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

    // Explicitly close the recording context to flush the .webm file.
    await mobile.close();

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
    console.log("MOBILE_NAV_EXPANDED_HEIGHT_PX=" + expandedNavHeight);
    console.log("MOBILE_AGENT_SIDEBAR_HEIGHT_PX=" + sidebarSize.height);
    console.log("ENQUIRY_SERVER_VALIDATION_422=PASS");
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
