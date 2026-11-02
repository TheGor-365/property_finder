# Property Finder — визуальная приёмка (RU)

Версия: `work/property-finder-ui-content`. Основная ветка `work/property-finder-upgrade-lab` содержит только прошлый этап. Этот документ — checklist, не подтверждение выполненной приёмки.

## 0. Предусловия
- Локальное рабочее дерево `property_finder_upgrade` без незакоммиченных изменений.
- PostgreSQL: **только** изолированный `property-finder-upgrade-db-1`, Rails `RAILS_ENV=test`; никаких `db:reset`, `db:seed`, `db:drop` или удаления volumes.
- GitHub PR #2 имеет зелёную проверку по **последнему** SHA.
- Прежде чем переключать ветку, остановить существующий сервер `Ctrl+C` в терминале, где он запущен.

## 1. Получить код
```bash
git fetch origin work/property-finder-ui-content
git switch -c work/property-finder-ui-content --track origin/work/property-finder-ui-content
git status --short
git log -1 --oneline
```
Если локальная ветка уже существует, **не** создавать заново; проверить её содержимое перед `git switch`. Не использовать `git reset --hard` или `git clean`.

## 2. Подготовить контент и доступ
```bash
tmp/pf-ruby34-rails.sh pf:demo:articles
tmp/pf-ruby34-rails.sh pf:demo:grant_access
```
Первая задача создаёт 6 полных редакционных статей в **test**/**development** DB без перезаписи существующих статей. Повторный запуск должен вывести `PF_DEMO_ARTICLES_CREATED=0`. Вторая задача строго ограничена **test** DB, DEMO-аккаунтом `pf-catalog-showcase@example.invalid` и его 12 объявлениями, выводит новый пароль **только в локальном терминале**. Не копировать пароль в чат, GitHub, скриншоты.

Запуск локального UI через уже существующий локальный helper (если он доступен):
```bash
python3 "$(xdg-user-dir DOWNLOAD)/property_finder_start_ui.py"
```
Ожидать `SERVER_HTTP_READY=YES (200)`, открыть `http://127.0.0.1:3000`. Helper запускает Rails в Docker с тестовой БД. Сервер нужно перезапустить после переключения ветки: `RAILS_ENV=test` кэширует код.

## 3. Public UX
| URL | Проверить |
|---|---|
| `/` | Hero, настоящие ссылки на каталог/блог, карточки, desktop/mobile |
| `/properties` | Поиск, фильтр `For rent/sale`, min/max, спальни, сортировка, pagination |
| `/properties/663` | DEMO-метка, честная подпись к иллюстрации, агент, форма, успех/ошибка, responsive |
| `/blog` | 6 опубликованных текстов и самостоятельные иллюстрации, не пустая лента |
| `/posts/:id` | Полное содержание, активная ссылка назад и на каталог, удобная типографика |
| `/accounts/sign_in` | Login DEMO-агента, понятные ошибки; нельзя рекламировать test email как реальный |
| `/accounts/sign_up` | Не используется: регистрация Devise по адресу `/accounts/sign_up` должна создавать отдельный аккаунт только по инициативе тестировщика |
| `/accounts/password/new` | Форма recovery, delivery в test adapter, реальная почта НЕ настроена |

## 4. Agent UX после входа
| URL | Проверить |
|---|---|
| `/dashboard` | Нет белой полосы сверху, реальные числа/ссылка Enquiries, адаптивный sidebar |
| `/my/properties` | Список 12 DEMO-объявлений, view/edit, честное ограничение удаления с заявками |
| `/properties/new` | Секции, заполнение, ошибки обязательных полей, JPEG/PNG upload, сохранение |
| `/properties/:id/edit` | Статусы доступны согласно sale/rent, исправление, проверка reload |
| `/enquiries` | Видны только заявки собственных объявлений, статус `New → Contacted → Closed` устойчив после reload |
| `/profile/:id` | Визитка агента, реальные поля, нет пустой кнопки Call, working contact |
| `/accounts/edit` | Контакты, фото, cover, текущий пароль, ошибки валидации |

Дополнительный админский профиль нужен лишь для проверки `/posts`, `/posts/new`, `/posts/:id/edit`, `/accounts`. **Не** повышать привилегии DEMO-агента и не менять учётные данные других пользователей ради QA.

## 5. Критерии готовности
- Все активные ссылки открывают реальные страницы; никаких `href='#'`, мок-кнопок и обещаний несуществующих функций.
- Ввод и сохранение устойчивы к reload; ошибку можно исправить, не потеряв всю форму.
- Проверить desktop 1440px, tablet 768px, mobile 390px; меню, sidebar, поля не выходят за экран.
- Фото/иллюстрации подписаны правдиво; `DEMO` объявления не позиционируются как фактическая недвижимость.
- Developer Tools: нет JS errors, незагруженных изображений, HTTP 500 или публичных личных данных.
- После теста: `tmp/pf-ruby34-rails.sh pf:demo:revoke_access`. Это только ротация тестового пароля, сохранённые заявки/объявления не удаляются.

CI проверяет код и сборку, **не** визуальную приёмку. До подтверждения всех пунктов PR остаётся draft; `master` не изменяется.
