# Property Finder — отдельный Railway production deployment

**АКТУАЛЬНО НА 03.11.2026: LIVE DEPLOY.** Документ ниже изначально был предрелизным чек-листом; указания про «0 работающих сервисов», staged-состояние и отсутствие публичного домена — исторические, не текущая действительность. Railway web+Postgres `SUCCESS`, `/healthz` HTTP 200, production deploy `61bbee63-e492-4ac1-852a-0c49d6e36b14` / commit `7b290310623feff47050c3bd808fe6504115cbd1`. [Публичное DEMO](https://property-finder-web-production.up.railway.app/). SMTP выключен намеренно, домен Railway (не куплен пользовательский), тома подключены; backup/restore и upload persistence не доказаны. История ниже оставлена для технической трассировки.

---

**ИСТОРИЧЕСКИЙ ПЛАН (до публикации):** Отдельный приватный Railway-проект `property-finder` создан (project ID `367956af-bb83-4a01-b093-f7342ca58a4a`, production environment `3bbabef4-5625-43b0-9796-1e03c4363ae7`). В нём пока 0 работающих сервисов и 0 томов. Не трогать `mellow-stillness`, `gor-web-resume`, `classifieds-rails-project-65` и их базы/тома.

## Входные условия
- Отдельный Railway project **property-finder** и свой PostgreSQL instance. Никаких общих production DB с другими приложениями.
- GitHub source: `TheGor-365/property_finder`; branch `work/property-finder-ui-content` до приемки. `master` исторический, не deploy.
- Dockerfile в корне, Ruby 3.4.12, Rails 8.1.4, Node 22 для сборки, Puma `PORT`; `DATABASE_URL` из отдельного PostgreSQL.
- Volume `/app/public/uploads` на отдельном сервисе. Важное: пустой Volume скрывает содержимое image по этому пути. **Не переносить исторические медиа и не удалять их без бэкапа.**
- Static files разрешены, заголовки X-Forwarded-Proto и HTTPS проверяются.
- Не размещать test DEMO credentials/password в deployment env. Данные для showcase отдельно импортировать только после проверки их происхождения, маркировки DEMO и безопасности.

## Required environment names (значения только в Railway Variables, не в GitHub/чат)
- `RAILS_ENV=production`
- `DATABASE_URL`: service reference from dedicated PostgreSQL (включая SSL/параметры по требованиям Railway)
- `APP_HOST`: публичный hostname **без** `https://` или пути
- `SECRET_KEY_BASE`: новый криптографически случайный секрет, не из Git и не из локального demo
- `PROPERTY_FINDER_MAIL_FROM`: подтвержденный адрес отправителя
- `SMTP_ADDRESS`, `SMTP_PORT=587`, `SMTP_USERNAME`, `SMTP_PASSWORD`: настройки реального проверенного email-провайдера
- `RAILWAY_VOLUME_MOUNT_PATH`: Railway runtime config, ожидается `/app/public/uploads`; не подставлять фальшивое значение вместо физического mount
- `RAILS_LOG_TO_STDOUT=1`, `RAILS_SERVE_STATIC_FILES=1` (значения уже в образе)

Entry point блокирует запуск при отсутствии обязательных переменных или writable volume. Rails в production: force SSL, info logs, фильтрация PII и SMTP с TLS verification.

## Проверка здоровья
`GET /healthz` отвечает HTTP 200 только если приложение способно выполнить `SELECT 1` в собственной базе. Railway healthcheck задан в `railway.json`, Dockerfile выбирается автоматически. HTTP 503 при недоступности БД — это отказ readiness, а не публичная выдача подробностей.

## Безопасный порядок выпуска
1. Убедиться, что PR CI зелёный на точном SHA; проверить отсутствие актуальных секретов в Git history (исторический Google Maps key и пароль из старой конфигурации требуют проверки/ротации).
2. Создать **отдельный** проект Property Finder; присоединить PostgreSQL и dedicated Volume, настроить secrets без вывода в чат. Задать source branch и root Dockerfile. Не подключать действующие базы другого проекта.
3. Выполнить **миграции БД** в отдельном деплой-контексте после резервирования данных; начальный deploy пустой DB может использовать `bundle exec rails db:prepare`. Не смешивать миграцию с восстановлением/очисткой.
4. Проверить `GET /`, `/properties`, `/blog`, `/accounts/sign_in` и сценарии гостя/агента. Если без реального SMTP, нельзя считать login recovery готовым.
5. Загрузить небольшой разрешенный PNG и проверить original/thumbnail по HTTP; перезапустить **только** Property Finder, убедиться, что файлы остались. Отдельно проверить бэкап **и восстановление** тома и PostgreSQL.
6. Включить мониторинг, домен/HTTPS, бюджетные лимиты Railway, healthcheck. Проверить отрицательные сценарии и запреты доступа.
7. Только после proof / release checklist — перевод PR из draft, merge в согласованную ветку и выпуск портфолио.

## Известные незакрытые риски
- Для Rack::Attack production пока не настроено общее хранилище счётчиков на несколько инстансов. Один инстанс и DB-проверки частоты — ограничение, не эквивалент защиты от ботов.
- Production SMTP **не проверен** фактической доставкой.
- Текущий volume guard проверяет переменную mount path и права записи, **не доказывает** долговечность volume — это доказывает только тест redeploy/restore.
- Демонстрационные SVG не являются фотографиями реальных объектов. Нельзя публиковать их как реальные объявления.
- Google Maps для вымышленных координат не активировать.


## Public DEMO-only release without email (03.11.2026)

The owner authorized a Railway public deploy, postponing only outbound SMTP.
`PROPERTY_FINDER_EMAIL_DELIVERY=disabled` is explicit. Enquiries are stored, but **no emails are sent** (including Devise password recovery). Public portfolio records require `PF_PUBLIC_SHOWCASE=enabled` and the separate idempotent `pf:demo:public_showcase` rake task after schema preparation. The only seeded agent uses an `.invalid` example address and a random unknown password; no account credentials are embedded in source.

The web service must have a writable persistent volume at `/app/public/uploads` and `RAILWAY_VOLUME_MOUNT_PATH` set to the same. `DATABASE_URL` must refer to its own Railway Postgres service, never localhost. Run pre-deploy database preparation and `pf:demo:public_showcase` against the **new empty production database only**. Public names, addresses, prices, articles and illustrations must be labelled fictitious; no photography of actual inventory is claimed.

Before enabling email later: set `PROPERTY_FINDER_EMAIL_DELIVERY=smtp`, SMTP variables and verified sender/domain as a separate scoped change after end-to-end delivery testing. Until then the public demo's inbound messages have no notification delivery and should contain no personal or sensitive information.
