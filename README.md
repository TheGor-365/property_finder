# Property Finder

**Ruby on Rails property-search and agent-workflow portfolio project.** A modernized legacy application demonstrating search, listing management, role-restricted workspaces, editorial content and enquiries stored in PostgreSQL.

> **Demonstration software, not a real estate marketplace.** The twelve `DEMO -` listings in the preserved local test environment are fictional. Their addresses and prices are examples; illustration assets are not photographs of actual properties. No property sale, lease or customer payment is represented.

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

**User-verified local acceptance:** home / catalogue / listing detail, agent dashboard, forms, enquiry inbox and profile introduction have been visually reviewed. The persistent profile-message workflow and status change were also checked through the browser. This does **not** constitute a production acceptance test.

## Technical stack

- Ruby **3.4.12**, Rails **8.1.4**, PostgreSQL and Puma 8
- Devise authentication; HTML ERB + Bootstrap 4.5
- Node 22, esbuild (replacing legacy Webpacker), Sprockets and SCSS
- CarrierWave + MiniMagick for media
- Action Mailer and Rack::Attack; Minitest integration tests
- Docker production build and optional Railway configuration (not deployed)

## Repository orientation

- `app/controllers/properties_controller.rb` / `app/models/property.rb` — listings
- `app/controllers/enquiries_controller.rb`, `app/controllers/agent_messages_controller.rb` — durable contact workflows
- `app/controllers/posts_controller.rb` — editorial journal
- `app/views/`, `app/assets/images/editorial/` — UI and original **illustrative** SVG assets
- `test/integration/` — HTTP, ownership, uploads, anti-abuse, navigation and presentation coverage
- `docs/PORTFOLIO_CASE_RU.md` — Russian case study and scope
- `docs/QA_UI_ACCEPTANCE_RU.md` — local browser QA checklist
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

The supplied `db/seeds.rb` does **not** populate a fresh database with twelve demonstration properties. Those records belong to a preserved, **isolated test database** used for visual acceptance. Do not copy, reset or publish somebody else's database to produce a mock showcase.

To run the automated suite in a correctly provisioned, isolated test PostgreSQL environment:

```bash
RAILS_ENV=test bin/rails db:prepare
RAILS_ENV=test bin/rails test test
```

**Local test harness note:** the maintainer uses an additional `tmp/pf-ruby34-rails.sh` Docker wrapper on Linux; it is a local, non-versioned helper and is not required for the repository's standard Rails commands. Never run destructive database tasks against an existing demonstration database or production service.

## Current acceptance evidence

- GitHub Actions on the modernization branch: **95 Rails tests / 553 assertions / 0 failures / 0 errors / 0 skips** as of 2026-11-02.
- Asset precompilation and production Docker build passed CI.
- User browser screenshots confirmed the agent profile contact flow and corrected navbar layout.
- Separate Railway project resources are **staged, not deployed**; there is **no confirmed public Property Finder URL**, no working production SMTP and no completed restore/redeploy persistence test.
- Historical key exposure and production-grade distributed abuse protection still require release review.

### Demo image examples

These are original architectural **illustrations**, not photos of actual listings:

![Fictional illustrated demo residence](app/assets/images/editorial/courtyard.svg)
![Fictional illustrated demo architecture](app/assets/images/editorial/apartment.svg)

## Status and limitations

The current work lives in the [modernization pull request](https://github.com/TheGor-365/property_finder/pull/2). The repository's default `master` branch is historical: use the PR branch to review modernization.

This is a **work-in-progress engineering portfolio case**. Actual customer usage, revenue, verified real-property data, production SMTP delivery, backups and public-service uptime are **not claimed**. Buying a domain and activating a paid Railway deployment have been expressly deferred.

---

[Русская версия кейса](docs/PORTFOLIO_CASE_RU.md) · [Testing checklist (RU)](docs/QA_UI_ACCEPTANCE_RU.md) · [Open engineering gates](https://github.com/TheGor-365/property_finder/issues/3)
