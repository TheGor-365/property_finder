# Property Finder — домен и транзакционная почта с нуля

Checkpoint: 2026-11-02. Это **план к выполнению**, не подтверждение купленного домена, настроенного SMTP или опубликованного сайта. Не публиковать API-ключи, пароли, карту, личные документы и DNS access tokens ни в GitHub, ни в ChatGPT.

## Принятое направление
- Web: бесплатный Railway-поддомен `*.up.railway.app` на первом тестовом запуске; собственный web-domain можно привязать позже.
- Outbound mail: Resend Free + ActionMailer SMTP. По публичному тарифу от 2026-11-02: 3000 писем/месяц, не более 100/день, 3 подтверждённых домена, $0/мес. Тариф не гарантирует доставку, лимиты могут меняться.
- Один **собственный** домен разумнее нескольких доменов для демо-проектов. Предпочтительно нейтральное имя для Rails-портфолио; на нём можно создать `property.<domain>` (веб) и `mail.<domain>` или `notify.<domain>` (почта). **Имя сначала проверить на доступность и отсутствие очевидного конфликта с чужими брендами.**
- Бюджет: для ориентира web.am публикует .am за 9600 AMD/год, .com за 15600 AMD/год. Точная цена, доступность и способ оплаты проверяются при оформлении. Reg.am заявляет Visa/Mastercard/ArCa, Idram, банковскую оплату. Оплата/регистрация — действие владельца.
- Временно не брать обещания платных планов/расходов на Railway или домен без отдельного согласования.

## Railway — подготовлено, НО НЕ ПРИМЕНЕНО
Проект `property-finder`: `367956af-bb83-4a01-b093-f7342ca58a4a`; production env `3bbabef4-5625-43b0-9796-1e03c4363ae7`.

Staged-only resources:
1. `property-finder-web` source `TheGor-365/property_finder`, branch `work/property-finder-ui-content`, pinned tested commit `bc74c27c94f797f1fc4021b481f9845c7f55883e`;
2. `Postgres` using Railway template `postgres`, pinned template PostgreSQL **18** image with own `postgres-volume` mounted at `/var/lib/postgresql/data`; actual PG18 compatibility still requires running acceptance;
3. `property-finder-uploads`, 512 MB, mounted to `property-finder-web` at `/app/public/uploads`;
4. Staged **nonsecret** web variables: `RAILS_ENV`, `RAILS_LOG_TO_STDOUT`, `RAILS_SERVE_STATIC_FILES`, `DATABASE_URL=${{Postgres.DATABASE_URL}}`, `SMTP_ADDRESS=smtp.resend.com`, `SMTP_PORT=587`, `SMTP_USERNAME=resend`.

No deployment was accepted, no public service exists. All settings are staged. **Do not click Deploy** until the outstanding gates below are satisfied and costs approved.

## Human action — domain
1. Pick and **buy** one domain at registrar of choice with true owner identity, current payment method, renewal price and auto-renew rules. Do not use another person's payment identity.
2. Gain DNS management access. No website hosting needs to be bought from registrar; Railway serves the app.
3. Send assistant only **registered domain name** and screenshots of DNS records with personal information and keys hidden. The assistant can then prepare precise DNS steps and Railway custom domain mapping.

## Human action — Resend
1. Create Resend account on `https://resend.com` with legitimate details. Availability and account activation are provider decisions. Start Free; do not buy add-ons.
2. Add a **sending subdomain you control**, e.g. `notify.<domain>`, in Resend > Domains. Copy exactly the DNS records displayed by Resend: DKIM and the SPF/TXT/MX records indicated by the current setup. Avoid duplicate SPF at one DNS name. DMARC policy must be aligned, not invented.
3. Wait for Resend to show `Verified`. Only then create a **sending-limited SMTP API key**, entering it **privately in Railway** as `SMTP_PASSWORD`. Never paste key or credentials in chat or Git.
4. Use `PROPERTY_FINDER_MAIL_FROM=Property Finder <notifications@notify.<domain>>`, an address under the verified sending domain. `SMTP_ADDRESS=smtp.resend.com`, `SMTP_PORT=587`, `SMTP_USERNAME=resend` already staged. Port 587 uses STARTTLS. Verify the SMTP API key's permissions and account eligibility.

Important: SMTP is for **outbound** notifications and Devise password reset; it does not create an incoming mailbox. `notifications@` is not a support inbox unless configured separately. For replies, configure a real inbox and Reply-To or state that the address is no-reply. Test with verified real addresses only; do not send to `@example.invalid` demo accounts. Resend test-only domain cannot be used for arbitrary external recipients.

## Secrets still outstanding — never put in source
- `SECRET_KEY_BASE` (cryptographically random, new production key);
- `SMTP_PASSWORD` (Resend API key, generated after account/domain verification);
- `PROPERTY_FINDER_MAIL_FROM` (actual verified sender);
- `APP_HOST` (actual Railway-generated or custom host without protocol).
- `DATABASE_URL` is already linked to staged, dedicated Postgres; do not copy resolved connection secrets into chat.

## Deployment gates
1. CI success for pinned release SHA, check historical leaked keys/creds and rotate any still valid; ensure production data policy, privacy/terms, request abuse control, authorised images and no real-looking DEMO misrepresentation.
2. Confirm owner approves expected monthly Railway expenses, resource use budget/alert/limits and domain purchase.
3. Publish/add domain only when app is ready, verify HTTPS and HTTP /healthz on dedicated production Postgres.
4. Perform `db:prepare`/migrations on the NEW Postgres only. Never reset other databases. Ensure no DEMO login secrets or production passwords exposed.
5. End-to-end live sender verification, Devise reset, Enquiry, AgentMessage + delivery status; no delivery to fictional .invalid addresses.
6. Upload original + thumbnail through public URL; restart/redeploy and verify preserved files. Configure PostgreSQL and media volume backup and restore rehearsal.
7. Release only after checks; PR remains draft, master and existing Railway projects untouched.

Sources checked 2026-11-02: https://docs.railway.com/networking/domains/working-with-domains ; https://docs.railway.com/volumes ; https://docs.railway.com/pricing/plans ; https://resend.com/pricing ; https://resend.com/rails ; https://www.web.am/en/services/domain-registration ; https://www.reg.am/en .
