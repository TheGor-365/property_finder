# Property Finder

**Ruby on Rails property-search and agent-workflow portfolio project.** A modernized legacy application demonstrating search, listing management, role-restricted workspaces, editorial content and enquiries stored in PostgreSQL.

> **Demonstration software, not a real estate marketplace.** The twelve `DEMO -` listings are fictional, including the examples on the deployed public showcase. Their addresses and prices are examples; illustration assets are not photographs of actual properties. No property sale, lease or customer payment is represented.

## Implemented and verified

| Area | Functionality |
| --- | --- |
| Public catalogue | Available-only search, sale/rent filters, price, bedrooms, ordering and pagination |
| Listing details | Status, amenity information, explanatory imagery, agent profile and server-validated enquiry form |
| Agent workspace | Account login, own-listing create/edit/delete (deletion restricted when enquiries exist), status management and actual DB-backed counters |
| Contact workflow | Persistent listing enquiries and direct agent-profile messages, private inbox, `New / Contacted / Closed`, best-effort mail notifications |
| Editorial journal | Published article feed, individual articles, admin-only editing, cover uploads and thumbnails |
| Uploads | CarrierWave file validation (JPEG/PNG, 5 MB, content signature), resized thumbnails; production guard against ephemeral storage |
| Reliability / safety | Ownership authorization, guest restrictions, basic honeypot and rate limits, HTML/JSON public catalogue consistency, Rails integration tests |
| User interface | Responsive public pages, separate agent workspace, accessible form labels, contextual page titles and private-page noindex tags |

**Local and public acceptance:** owner-reviewed screenshots verify home, catalogue/filtering, details, contact modal, dashboard, public agent profile and settings in the live Railway app (10 desktop + 10 mobile PNG). Chromium CI independently verified browser form persistence and status changes on a separate ephemeral test database. Those two evidence types must not be conflated; not every production mutation has been smoke-tested.

## Technical stack

- Ruby **3.4.12**, Rails **8.1.4**, PostgreSQL and Puma 8
- Devise authentication; HTML ERB + Bootstrap 4.5
- Node 22, esbuild (replacing legacy Webpacker), Sprockets and SCSS
- CarrierWave + MiniMagick for media
- Action Mailer and Rack::Attack; Minitest integration tests
- Docker production build and live dedicated Railway production deployment

## Repository orientation

- `app/controllers/properties_controller.rb` / `app/models/property.rb` — listings
- `app/controllers/enquiries_controller.rb`, `app/controllers/agent_messages_controller.rb` — durable contact workflows
- `app/controllers/posts_controller.rb` — editorial journal
- `app/views/`, `app/assets/images/editorial/` — UI and original **illustrative** SVG assets
- `test/integration/` — HTTP, ownership, uploads, anti-abuse, navigation and presentation coverage
- `docs/PORTFOLIO_CASE_RU.md` — Russian case study and scope
- `docs/QA_UI_ACCEPTANCE_RU.md` — local browser QA checklist
- `docs/BROWSER_QA_EVIDENCE_RU.md` — browser screenshot manifest and evidence boundaries
- `docs/UPLOAD_STORAGE_PRODUCTION_RU.md` and `docs/RAILWAY_RELEASE_CHECKLIST_RU.md` — deployment gates, **not completed deployment reports**

## Local development (own PostgreSQL instance)

You need Ruby 3.4.12, Bundler compatible with `Gemfile.lock`, PostgreSQL, Node 22, Yarn and ImageMagick. Use **your own local database credentials** via environment variables; do not paste credentials into issues or Git history.

```bash
bundle install
yarn install --frozen-lockfile
bin/rails db:prepare
bin/rails assets:precompile
bin/rails server
```

The supplied `db/seeds.rb` does **not** populate a fresh database with twelve demonstration properties. A separate, guarded and idempotent `pf:demo:public_showcase` task initializes 12 clearly fictional records and six demo articles in the designated Railway production showcase only when `PF_PUBLIC_SHOWCASE=enabled`. Do not run this against another database or copy over someone else's data.

To run the automated suite in a correctly provisioned, isolated test PostgreSQL environment:

```bash
RAILS_ENV=test bin/rails db:prepare
RAILS_ENV=test bin/rails test test
```

**Local test harness note:** the maintainer uses an additional `tmp/pf-ruby34-rails.sh` Docker wrapper on Linux; it is a local, non-versioned helper and is not required for the repository's standard Rails commands. Never run destructive database tasks against an existing demonstration database or production service.

## Current acceptance evidence

- GitHub Actions on the modernization branch: **98 Rails tests / 574 assertions / 0 failures / 0 errors / 0 skips** as of 2026-11-02.
- Asset precompilation and production Docker build passed CI.
- User browser screenshots confirmed the agent profile contact flow and corrected navbar layout.
- [Chromium Browser QA](https://github.com/TheGor-365/property_finder/actions/runs/41528093906) verified 390px mobile and 1440px desktop layouts, fully expanded menus, 422 form recovery, persisted enquiry and status after reload, producing **12 browser screenshots**. The artifact has limited GitHub retention; a copy is preserved in the owner's private Drive (see [screenshot manifest](docs/BROWSER_QA_EVIDENCE_RU.md)).
- **Railway production is live:** [public Property Finder demo](https://property-finder-web-production.up.railway.app/) (service and separate Postgres `SUCCESS`, `/healthz` HTTP 200, deployment `61bbee63-e492-4ac1-852a-0c49d6e36b14`, code `7b290310`). It hosts 12 fictional listings and six educational articles. The owner provided 20 desktop/mobile production screenshots. Outgoing production SMTP is deliberately **disabled**; media redeploy persistence, restore and real end-to-end production contact delivery have not all been verified.
- Historical key exposure and production-grade distributed abuse protection still require release review.

### Demo image examples

These are original architectural **illustrations**, not photos of actual listings:

![Fictional illustrated demo residence](app/assets/images/editorial/courtyard.svg)
![Fictional illustrated demo architecture](app/assets/images/editorial/apartment.svg)

## Status and limitations

The current work lives in the [modernization pull request](https://github.com/TheGor-365/property_finder/pull/2). The repository's default `master` branch is historical: use the PR branch to review modernization.

This is a **live, publicly accessible engineering portfolio demonstration**. Actual customer usage, revenue, verified real-property data, SMTP delivery, successful backup restoration and guaranteed service uptime are **not claimed**. A custom domain and outgoing email are deferred; Railway is deployed and may incur normal workspace charges. Source branch PR #2 remains draft and is not merged into historical `master`.

---

[Русская версия кейса](docs/PORTFOLIO_CASE_RU.md) · [Testing checklist (RU)](docs/QA_UI_ACCEPTANCE_RU.md) · [Open engineering gates](https://github.com/TheGor-365/property_finder/issues/3)
