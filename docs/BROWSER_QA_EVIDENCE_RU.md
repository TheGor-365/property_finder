# Property Finder — подтверждение браузерной QA

Дата: **02.11.2026**. Код, проверенный в настоящем Chromium: **`7890ce411180a03797b890d337f9f8288af50444`**.

[GitHub Actions: Browser QA run 41528093906 — PASS](https://github.com/TheGor-365/property_finder/actions/runs/41528093906).

Архив 12 скриншотов сохранён и проверен повторным чтением в закрытой папке Google Drive `04_PROPERTY_FINDER / 02_SCREENSHOTS_VERIFIED`: [PROPERTY_FINDER_BROWSER_QA_2026-11-02_7890ce4.zip](https://drive.google.com/file/d/1YmygiaIHPHwbSV_I-R3Yo4mW0d90A31b/view). У публики **нет подтверждённого доступа** к частному Drive; артефакты Actions также имеют ограниченный срок хранения.

## Изолированная тестовая среда

`script/browser_qa_seed.rb` запускается **только** с `RAILS_ENV=test`, `GITHUB_ACTIONS=true`, `PF_BROWSER_QA=1`, проверяет имя БД на `test` и отсутствие существующих Account и Property. В новой временной PostgreSQL 16 созданы вымышленный агент и два DEMO-объекта. Шесть DEMO-статей загружены идемпотентной задачей. Тестовый пароль хранится только в временном `tmp/browser_qa/credentials.json` и **не входит** в артефакт.

## Подтверждённые результаты

- Chromium mobile **390×844** и desktop **1440×900**.
- Navbar → hero: **0 px**; горизонтальное переполнение проверенных страниц отсутствует.
- Мобильный публичный dropdown действительно раскрыт, высота **158 px**.
- Мобильное меню кабинета больше не занимает весь экран: **≈287 px**.
- Неверная форма возвращает **HTTP 422**, показывает ошибки и сохраняет ввод.
- Корректный Enquiry сохраняется в PostgreSQL, появляется в приватном inbox; после обновления и повторной загрузки статус **Contacted** остаётся сохранённым.
- Необработанные page JavaScript errors не обнаружены.

## 12 снимков

| Файл | Подтверждаемая страница |
| --- | --- |
| `01-mobile-navigation-open.png` | Мобильная главная, раскрытый navbar |
| `02-mobile-catalogue.png` | Мобильный каталог и фильтры |
| `03-mobile-enquiry-modal.png` | Мобильная контактная форма |
| `04-mobile-enquiry-validation.png` | Ошибки 422, сохранённый ввод |
| `04-mobile-enquiry-confirmation.png` | Подтверждение получения обращения |
| `05-mobile-agent-workspace.png` | Компактный мобильный sidebar |
| `06-mobile-agent-inbox.png` | Inbox после изменения статуса |
| `07-desktop-home.png` | Desktop главная |
| `08-desktop-catalogue.png` | Desktop каталог |
| `09-desktop-detail.png` | Desktop карточка объекта |
| `10-desktop-agent-profile.png` | Desktop профиль |
| `11-desktop-journal.png` | Desktop блог |

Изображения показывают только фиктивные тестовые данные и **не** подтверждают реальные продажи, пользователей, доход или production.

## Осталось

Планшет **768 px**, малый мобильный экран **320 px**, Safari/Firefox, клавиатурная и screen-reader приёмка, реальный upload/redeploy/restore, SMTP и публичный Railway-деплой **не подтверждены**. Domain/SMTP/платный деплой отложены пользователем. Для публичного портфолио ещё нужны отобранная галерея и видео без временных уведомлений.
