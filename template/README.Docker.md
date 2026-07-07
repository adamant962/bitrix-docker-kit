# Docker-сборка для Bitrix-проектов

**Важные замечания:**
- PHP 8.0 / 8.1 — **legacy-режим**, только для старых проектов, требующих обратной совместимости.
- **Базовый актуальный профиль:** PHP 8.2 + MySQL 8.0 — рекомендован для большинства современных проектов.
- **macOS Apple Silicon:** поддерживается через `docker-compose.platform-amd64.yml`, но amd64-эмуляция работает медленнее нативных arm64-образов.
- **Windows:** настоятельно рекомендуется хранить проект внутри файловой системы WSL2 (например, `/home/user/projects/...`), а не в `C:\...`. Bind mount из Windows идёт через сетевую прослойку и значительно замедляет работу Bitrix из-за большого количества файлов кеша.

## Структура файлов

```
project-root/
├── docker/
│   ├── nginx/
│   │   ├── default.conf              # HTTP Nginx под Bitrix
│   │   └── https.conf                # HTTPS Nginx под Bitrix
│   ├── certs/
│   │   └── .gitkeep                  # Каталог для локальных сертификатов
│   ├── php/
│   │   ├── Dockerfile                # PHP-FPM (8.0–8.4)
│   │   ├── php.ini                   # Базовые настройки PHP
│   │   ├── opcache.ini               # OPcache + APCu
│   │   └── xdebug.ini                # Xdebug (включается через .env)
│   ├── db/
│   │   ├── my.cnf                    # charset/collation MySQL/MariaDB
│   │   └── init/
│   │       └── 01-mysql8-grants.sh   # Grants для новых MySQL 8 volumes
│   └── scripts/
│       ├── import-db.sh              # Импорт дампа
│       ├── dump-db.sh                # Создание дампа
│       ├── fix-permissions.sh        # Права на cache/upload
│       ├── fix-install-permissions.sh # Права на этапе установки Bitrix
│       ├── fix-mysql8-grants.sh      # Grants для существующих MySQL 8 volumes
│       ├── generate-https-cert.sh    # Генерация mkcert-сертификата
│       ├── install-mkcert-ca-to-php.sh # Доверие mkcert CA внутри PHP-контейнера
│       └── show-mkcert-ca.sh         # Показ пути к mkcert root CA
├── docker-compose.yml                # Основной compose-файл
├── docker-compose.https.yml          # Override для HTTPS
├── docker-compose.platform-amd64.yml # Override для arm64 → amd64
├── .env.example                      # Шаблон переменных окружения
├── .gitignore                        # Исключения локальных сертификатов
├── .dockerignore                     # Исключения для сборки
└── README.Docker.md                  # Этот файл
```

## Быстрый старт

### 1. Скопировать .env.example → .env

```bash
cp .env.example .env
mkdir -p www
```

Отредактируйте `.env` под свой проект (домен, БД, версии PHP/MySQL).
Для новых проектов рекомендуется `PROJECT_ROOT=./www`: тогда в корне проекта остаются Docker-файлы, а Bitrix устанавливается в `www/`.
Для старых проектов, где `bitrix/`, `local/` и `upload/` уже лежат в корне, оставьте `PROJECT_ROOT=.`.

### 2. Добавить домен в hosts

```bash
# Windows — C:\Windows\System32\drivers\etc\hosts
# macOS/Linux — /etc/hosts
127.0.0.1 vegaproject.loc
```

### 3. Собрать и запустить

```bash
docker compose build
docker compose up -d
```

### 4. Импортировать базу данных

Первый способ — положить дамп в `docker/db/init/init.sql` и запустить `docker compose up -d` (выполнится только при первом создании volume).

Второй способ — импортировать через скрипт:

```bash
chmod +x docker/scripts/*.sh
docker/scripts/import-db.sh dump.sql
```

### 5. Проверить

```bash
docker compose ps
docker compose exec php php -v
docker compose exec php php -m
docker compose exec php composer --version
```

Откройте `http://vegaproject.loc` в браузере.

## Выбор версии PHP

В `.env` укажите нужный образ:

```env
# PHP 8.0 (для старых проектов)
PHP_IMAGE=php:8.0-fpm-bullseye

# PHP 8.1
PHP_IMAGE=php:8.1-fpm-bullseye

# PHP 8.2 (рекомендуется для актуального Bitrix)
PHP_IMAGE=php:8.2-fpm-bookworm

# PHP 8.3
PHP_IMAGE=php:8.3-fpm-bookworm

# PHP 8.4 (тестовый)
PHP_IMAGE=php:8.4-fpm-bookworm
```

После смены версии выполните пересборку:

```bash
docker compose build php
docker compose up -d
```

**Важно:** установка расширений через `docker-php-ext-install` и `pecl` работает на всех версиях PHP 8.0–8.4 одинаково.
Если при сборке возникают ошибки, проверьте, что выбранный образ существует на Docker Hub.

## Выбор версии MySQL / MariaDB

```env
# MySQL
DB_IMAGE=mysql:5.7    # legacy, может не работать на Apple Silicon
DB_IMAGE=mysql:8.0    # рекомендовано
DB_IMAGE=mysql:8.4    # тестовый

# MariaDB (совместима с MySQL)
DB_IMAGE=mariadb:10.6
DB_IMAGE=mariadb:10.11
DB_IMAGE=mariadb:11.4
```

**Матрица совместимости:**

| PHP | MySQL | Статус |
|---|---|---|
| 8.0 | 5.7 / 8.0 | legacy, для старых проектов |
| 8.1 | 5.7 / 8.0 | legacy |
| 8.2 | 8.0 | базовый безопасный профиль |
| 8.3 | 8.0 / 8.4 | тестовый / актуальный |
| 8.4 | 8.4 | тестовый, проверять совместимость модулей |

**Рекомендация:** сначала повторите старое окружение (версию PHP/MySQL, которая была в OpenServer), потом обновляйте поэтапно.

### Grants для MySQL 8

Для MySQL 8 Docker Kit добавляет `SESSION_VARIABLES_ADMIN` и `SYSTEM_VARIABLES_ADMIN` пользователю из `DB_USER`.
Это нужно Bitrix и некоторым дампам, которые меняют session/system variables.

Для новых volumes grants применяются автоматически через:

```text
docker/db/init/01-mysql8-grants.sh
```

init-скрипты выполняются только при первом создании volume БД.
Если volume уже существует, используйте:

```bash
bash docker/scripts/fix-mysql8-grants.sh
docker compose restart php nginx
```

Для MySQL 5.7 эти grants не используются.

## Настройка Bitrix для подключения к БД

### Установка Bitrix через bitrixsetup.php

На шаге "Создание базы данных" укажите:

```text
Сервер: db
Пользователь базы данных: Существующий
Имя пользователя: bitrix
Пароль: bitrix_password
База данных: Существующая
Имя базы данных: значение DB_DATABASE из .env
```

Например:

```text
База данных: market
```

В Docker контейнер БД уже создаёт базу по переменной `DB_DATABASE`, поэтому обычно выбирайте "Существующая база данных".

Если выбираете "Новая база данных", в блоке администратора БД используйте:

```text
Логин: root
Пароль: значение DB_ROOT_PASSWORD из .env
```

### bitrix/php_interface/dbconn.php

Замените хост, логин и пароль на переменные окружения или укажите явно:

```php
<?php
define("BX_USE_MYSQLI", true);
define("DBPersistent", false);
$DBType = "mysql";
$DBHost = getenv('DB_HOST') ?: 'db';
$DBLogin = getenv('DB_USER') ?: 'bitrix';
$DBPassword = getenv('DB_PASSWORD') ?: '';
$DBName = getenv('DB_DATABASE') ?: 'bitrix';
$DBDebug = false;
$DBDebugToFile = false;

define("DELAY_DB_CONNECT", true);
define("CACHED_b_file", 3600);
define("CACHED_b_file_bucket_size", 10);
define("CACHED_b_lang", 3600);
define("CACHED_b_option", 3600);
define("CACHED_b_lang_domain", 3600);
define("CACHED_b_site_template", 3600);
define("CACHED_b_event", 3600);
define("CACHED_b_agent", 3660);
define("CACHED_menu", 3600);

define("BX_FILE_PERMISSIONS", 0644);
define("BX_DIR_PERMISSIONS", 0755);
@umask(~(BX_FILE_PERMISSIONS|BX_DIR_PERMISSIONS)&0777);

define("BX_DISABLE_INDEX_PAGE", true);
define("BX_UTF", true);
mb_internal_encoding("UTF-8");
```

### bitrix/.settings.php

```php
'connections' => [
    'value' => [
        'default' => [
            'className' => '\\Bitrix\\Main\\DB\\MysqliConnection',
            'host' => getenv('DB_HOST') ?: 'db',
            'database' => getenv('DB_DATABASE') ?: 'bitrix',
            'login' => getenv('DB_USER') ?: 'bitrix',
            'password' => getenv('DB_PASSWORD') ?: '',
            'options' => 1.0,
        ],
    ],
    'readonly' => true,
],
```

## Импорт и экспорт базы данных

### Первый запуск с дампом

Положите дамп в `docker/db/init/init.sql` и запустите контейнеры. Файл выполнится автоматически только при первом создании volume `db_data`.

### Импорт через скрипт

```bash
bash docker/scripts/import-db.sh dump.sql
```

### Создание дампа

```bash
bash docker/scripts/dump-db.sh dump.sql
```

### Импорт вручную

```bash
docker compose exec -T db sh -c 'mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_DATABASE"' < dump.sql
```

### Дамп вручную

```bash
docker compose exec db sh -c 'mysqldump --default-character-set=utf8mb4 --single-transaction --routines --triggers -u"$DB_USER" -p"$DB_PASSWORD" "$DB_DATABASE"' > dump.sql
```

## Права на директории

Bitrix требует права на запись в cache, upload и другие директории.
Скрипт `fix-permissions.sh` выставляет права только на нужные папки (без `chmod -R 777`):

```bash
bash docker/scripts/fix-permissions.sh
```

Затрагиваемые директории:
- `bitrix/cache`
- `bitrix/managed_cache`
- `bitrix/stack_cache`
- `bitrix/html_pages`
- `bitrix/backup`
- `upload`

### Права на этапе установки Bitrix

Во время установки через `bitrixsetup.php` установщик может писать файлы прямо в document root сайта.
Если появляется ошибка:

```text
file_put_contents(/var/www/html/bitrixsetup.update): Permission denied
```

выполните:

```bash
bash docker/scripts/fix-install-permissions.sh
```

или, если скрипты исполняемые:

```bash
docker/scripts/fix-install-permissions.sh
```

Скрипт выставляет права так, чтобы файлы могли изменять и PHP-контейнер, и пользователь WSL/IDE.
Модель прав для локальной разработки: владелец - текущий пользователь WSL, группа - `www-data`, директории - `2775`, файлы - `664`, ACL - `rwX` для пользователя и группы `www-data`.

После завершения установки удалите установочные файлы:

```bash
rm -f www/bitrixsetup.php
rm -f www/bitrixsetup.update
```

Если `PROJECT_ROOT=.`:

```bash
rm -f bitrixsetup.php
rm -f bitrixsetup.update
```

Затем можно выполнить обычную настройку прав:

```bash
bash docker/scripts/fix-permissions.sh
```

### Медленная установка Bitrix и 504 Gateway Time-out

Во время установки Bitrix через `bitrixsetup.php` шаг "Обновление продукта" может выполняться долго.
Bitrix скачивает архивы обновлений, распаковывает файлы и обновляет модули.

Если появляется:

```text
504 Gateway Time-out nginx/1.27.5
```

это означает, что Nginx не дождался ответа PHP-FPM.

Docker Kit увеличивает таймауты Nginx/PHP до 600 секунд, но если ошибка повторяется:

```bash
docker compose -f docker-compose.yml -f docker-compose.https.yml restart nginx php
```

Проверьте логи:

```bash
docker compose logs -f nginx
docker compose logs -f php
```

Если после 504 Bitrix показывает:

```text
Временный файл "/var/www/html/bitrix/updates/update_archive.gz" не существует
```

нажмите "Повторить шаг".
Если ошибка повторяется, удалите временные файлы:

```bash
rm -f "${PROJECT_ROOT:-./www}/bitrix/updates/update_archive.gz"
rm -f "${PROJECT_ROOT:-./www}"/bitrix/updates/*.tmp
```

и снова нажмите "Повторить шаг".

Проверьте запись в `bitrix/updates`:

```bash
docker compose exec php sh -lc 'touch /var/www/html/bitrix/updates/.write-test && rm /var/www/html/bitrix/updates/.write-test && echo OK'
```

Если команда не выводит `OK`, выполните:

```bash
bash docker/scripts/fix-install-permissions.sh
```

## Cron (Bitrix-агенты)

Сервис `cron` вынесен в профиль. Запуск:

```bash
docker compose --profile cron up -d
```

Одновременно с другими профилями:

```bash
docker compose --profile cron --profile tools up -d
```

Команда cron: запуск `cron_events.php` каждые 60 секунд.

## Adminer (веб-интерфейс для БД)

Сервис `adminer` вынесен в профиль `tools`:

```bash
docker compose --profile tools up -d
```

Доступен по адресу: `http://localhost:${ADMINER_PORT:-8080}`
Например, если `ADMINER_PORT=8091` — `http://localhost:8091`

Сервер БД: `db`
Пользователь: `bitrix`
Пароль: из переменной `DB_PASSWORD`

## Xdebug

Для включения Xdebug установите в `.env`:

```env
ENABLE_XDEBUG=1
```

Пересоберите образ:

```bash
docker compose build php
docker compose up -d
```

Настройки Xdebug (`docker/php/xdebug.ini`):
- Режим: `debug`
- Порт: `9003`
- IDE key: `VSCODE`
- `discover_client_host: 1` — автоматическое определение хоста IDE

Для отключения — верните `ENABLE_XDEBUG=0` и пересоберите образ.

## Поддерживаемые окружения

### Windows + WSL2

**Рекомендации:**

1. Установите Docker Desktop с бэкендом WSL2.
2. Храните проект внутри файловой системы WSL (например, `/home/user/projects/project-name`), а не в `C:\...`.
3. Не держите проект в облачных папках (OneDrive, Dropbox).
4. Bitrix создаёт множество мелких файлов кеша — bind mount из Windows может работать медленно.
5. Для ускорения вынесите кеши Bitrix в named volumes (см. раздел «Производительность»).

### macOS Intel

```bash
cp .env.example .env
docker compose build
docker compose up -d
```

Всё работает без дополнительных настроек.

### macOS Apple Silicon (M1/M2/M3/M4)

Для современных образов (mysql:8.0, php:8.2+) дополнительных настроек не требуется:

```bash
cp .env.example .env
docker compose build
docker compose up -d
```

Для старых образов (mysql:5.7 и т.п.), которые не имеют arm64-версии, используйте override:

```bash
docker compose -f docker-compose.yml -f docker-compose.platform-amd64.yml up -d
```

Проверка архитектуры контейнера:

```bash
docker compose exec php uname -m
docker compose exec db uname -m
# aarch64 — arm64
# x86_64 — amd64 (эмуляция)
```

### Linux

```bash
cp .env.example .env
docker compose build
docker compose up -d
```

Если возникают проблемы с правами, настройте `HOST_UID` и `HOST_GID` в `.env`:

```env
HOST_UID=$(id -u)
HOST_GID=$(id -g)
```

## Производительность

### Named volumes для кешей Bitrix

Для ускорения на Windows и macOS можно вынести кеши Bitrix в named volumes.
Добавьте в `docker-compose.yml` (секция `volumes` сервиса `php`):

```yaml
volumes:
  - bitrix_cache:/var/www/html/bitrix/cache
  - bitrix_managed_cache:/var/www/html/bitrix/managed_cache
  - bitrix_stack_cache:/var/www/html/bitrix/stack_cache
```

И в корневую секцию `volumes`:

```yaml
volumes:
  db_data:
  bitrix_cache:
  bitrix_managed_cache:
  bitrix_stack_cache:
```

**Важно:** `upload/` не выносить в anonymous volume — там пользовательские файлы проекта.
Если выносите `upload/` в named volume, обеспечьте резервное копирование.

### macOS: Synchronized File Shares

Если Docker Desktop подписка позволяет, включите Synchronized File Shares для ускорения обмена файлами между macOS и контейнером.

## Команды для проверки

```bash
# Проверка конфигурации
docker compose config
docker compose -f docker-compose.yml -f docker-compose.https.yml config

# Сборка
docker compose build

# Запуск
docker compose up -d

# Запуск с HTTPS
bash docker/scripts/generate-https-cert.sh
docker compose -f docker-compose.yml -f docker-compose.https.yml up -d

# Статус
docker compose ps

# Проверка Nginx
docker compose exec nginx nginx -t

# Перезапуск Nginx
docker compose restart nginx

# Логи
docker compose logs -f nginx
docker compose logs -f php
docker compose logs -f db

# PHP
docker compose exec php php -v
docker compose exec php php -m
docker compose exec php composer --version

# MySQL
docker compose exec db mysql --version
docker compose exec db sh -lc 'mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES;"'
docker compose exec db sh -lc 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;"'
bash docker/scripts/fix-mysql8-grants.sh

# Архитектура
docker compose exec php uname -m
docker compose exec db uname -m
```

## Запуск нескольких Bitrix-проектов одновременно

Сборка позволяет запускать несколько Bitrix-проектов на разных версиях PHP и MySQL параллельно.
Каждый проект работает в своём Docker Compose project с изолированными контейнерами.

### Уникальные параметры для каждого проекта

При одновременном запуске нескольких проектов эти параметры `.env` должны быть разными:

| Параметр | Обязательно уникальный? | Почему |
|---|---|---|
| `COMPOSE_PROJECT_NAME` | **Да** | Определяет имя проекта и префикс container_name |
| `HTTP_PORT` | **Да** | Порт на хосте — конфликт при overlap |
| `HTTPS_PORT` | **Да**, если включён HTTPS | Порт HTTPS на хосте — 443 обычно доступен только одному проекту |
| `DB_PORT_EXTERNAL` | **Да** (если опубликован) | Порт БД на хосте для внешних клиентов |
| `ADMINER_PORT` | **Да** (если запущен Adminer) | Порт Adminer на хосте |
| `DB_DATABASE` | Желательно | Технически может совпадать при отдельных db-контейнерах |

### Пример для двух проектов

```
/home/user/projects/
├── vegaproject/        # PHP 8.2 + MySQL 8.0
│   └── .env:           COMPOSE_PROJECT_NAME=vegaproject, HTTP_PORT=8081
│
└── atomdata/           # PHP 8.4 + MySQL 8.4
    └── .env:           COMPOSE_PROJECT_NAME=atomdata, HTTP_PORT=8082
```

```bash
# Терминал 1 — vegaproject
cd ~/projects/vegaproject
cp /path/to/bitrix-docker-kit/examples/php82-mysql80.env .env
# или если kit лежит рядом: cp ../bitrix-docker-kit/examples/php82-mysql80.env .env
# отредактировать .env: COMPOSE_PROJECT_NAME=vegaproject, HTTP_PORT=8081
docker compose up -d
docker compose exec php php -v    # → PHP 8.2

# Терминал 2 — atomdata
cd ~/projects/atomdata
cp /path/to/bitrix-docker-kit/examples/php84-mysql84.env .env
# или если kit лежит рядом: cp ../bitrix-docker-kit/examples/php84-mysql84.env .env
# отредактировать .env: COMPOSE_PROJECT_NAME=atomdata, HTTP_PORT=8082
docker compose up -d
docker compose exec php php -v    # → PHP 8.4
```

Доступ через порты:

```
http://localhost:8081  → vegaproject
http://localhost:8082  → atomdata
http://localhost:8083  → old-site
http://localhost:8084  → ещё один проект
```

### Шпаргалка по сочетаниям

Готовые примеры в папке `examples/`:

| Файл | PHP | DB | HTTP порт | HTTPS порт | DB порт | Adminer порт |
|---|---|---|---|---|---|---|
| `examples/php82-mysql80.env` | 8.2 | MySQL 8.0 | 8081 | 8441 | 3307 | 8091 |
| `examples/php84-mysql84.env` | 8.4 | MySQL 8.4 | 8082 | 8442 | 3308 | 8092 |
| `examples/php83-mysql80.env` | 8.3 | MySQL 8.0 | 8083 | 8443 | 3309 | 8093 |
| `examples/php80-mysql57.env` | 8.0 | MySQL 5.7 | 8084 | 8444 | 3310 | 8094 |
| `examples/php82-mariadb106.env` | 8.2 | MariaDB 10.6 | 8085 | 8445 | 3311 | 8095 |

### Исполняемые скрипты

После копирования скрипты `docker/scripts/*.sh` могут быть не исполняемыми.
Сделайте их исполняемыми одной из команд:

```bash
chmod +x docker/scripts/*.sh
chmod +x docker/db/init/01-mysql8-grants.sh
# или запускайте через bash:
bash docker/scripts/import-db.sh dump.sql
bash docker/scripts/dump-db.sh dump.sql
bash docker/scripts/fix-permissions.sh
bash docker/scripts/generate-https-cert.sh
bash docker/scripts/install-mkcert-ca-to-php.sh
bash docker/scripts/fix-mysql8-grants.sh
```

## Как подключить Docker Kit к новому проекту

Скопируйте файлы сборки в корень Bitrix-проекта и настройте `.env`:

```bash
# Скопировать файлы Docker Kit в проект
cp -R /path/to/bitrix-docker-kit/template/docker ./docker
cp /path/to/bitrix-docker-kit/template/docker-compose.yml ./docker-compose.yml
cp /path/to/bitrix-docker-kit/template/docker-compose.https.yml ./docker-compose.https.yml
cp /path/to/bitrix-docker-kit/template/docker-compose.platform-amd64.yml ./docker-compose.platform-amd64.yml
cp /path/to/bitrix-docker-kit/template/.gitignore ./.gitignore
cp /path/to/bitrix-docker-kit/template/.dockerignore ./.dockerignore
cp /path/to/bitrix-docker-kit/template/README.Docker.md ./README.Docker.md

# или если kit лежит рядом с проектом:
# cp -R ../bitrix-docker-kit/template/docker ./docker
# cp ../bitrix-docker-kit/template/docker-compose.yml ./docker-compose.yml
# cp ../bitrix-docker-kit/template/docker-compose.https.yml ./docker-compose.https.yml
# cp ../bitrix-docker-kit/template/docker-compose.platform-amd64.yml ./docker-compose.platform-amd64.yml
# cp ../bitrix-docker-kit/template/.gitignore ./.gitignore
# cp ../bitrix-docker-kit/template/.dockerignore ./.dockerignore
# cp ../bitrix-docker-kit/template/README.Docker.md ./README.Docker.md

# Скопировать пример окружения под вашу версию PHP/БД
cp /path/to/bitrix-docker-kit/examples/php82-mysql80.env .env
# или если kit лежит рядом: cp ../bitrix-docker-kit/examples/php82-mysql80.env .env

# Создать директорию сайта для новых проектов
mkdir -p www

# Отредактировать .env под проект
#   COMPOSE_PROJECT_NAME — уникальное имя проекта
#   PROJECT_DOMAIN — ваш локальный домен
#   PROJECT_ROOT — ./www для новых проектов, . для старых проектов с bitrix/local/upload в корне
#   HTTP_PORT — свободный порт на хосте
#   HTTPS_PORT — свободный HTTPS-порт, если включаете docker-compose.https.yml
#   HTTPS_DOMAIN — домен для локального HTTPS-сертификата
#   DB_DATABASE — имя базы данных

# Собрать и запустить
docker compose build
docker compose up -d

# Опционально: сгенерировать сертификат и запустить HTTPS
bash docker/scripts/generate-https-cert.sh
docker compose -f docker-compose.yml -f docker-compose.https.yml up -d
bash docker/scripts/install-mkcert-ca-to-php.sh

# Импортировать дамп базы
bash docker/scripts/import-db.sh dump.sql
```

```bash
# Опционально: OpenCode agents
cp /path/to/bitrix-docker-kit/template/opencode.json ./opencode.json
cp -R /path/to/bitrix-docker-kit/template/.opencode ./.opencode
cp /path/to/bitrix-docker-kit/template/AGENTS.md.example ./AGENTS.md
```

После копирования заполните AGENTS.md под конкретный проект. AGENTS.vega.md — только пример конкретного проекта, его нельзя использовать без редактирования.

### Если в проекте уже есть docker-compose.yml

Не копируйте `docker-compose.yml` поверх существующего. Лучше объедините сервисы вручную или используйте отдельную папку для Docker Kit.

Если в проекте уже есть `.gitignore`, не перезаписывайте его целиком: добавьте в него правила из `template/.gitignore` для `docker/certs`.

## HTTPS для локального Bitrix

HTTPS не включён по умолчанию. Для включения используется `docker-compose.https.yml`.
Обычный запуск `docker compose up -d` продолжает поднимать HTTP.
По умолчанию в `.env.example` используется `HTTPS_PORT=8443`, потому что 443 часто занят Windows/IIS/OpenServer/другим Docker-проектом.

Для браузера используется внешний `HTTPS_PORT`, например `https://market.loc:8443`.
Для PHP-контейнера `PROJECT_DOMAIN` должен указывать на `nginx` внутри Docker-сети.
Поэтому у сервиса `nginx` используется network alias `${PROJECT_DOMAIN}`.

### 1. Установить mkcert

Windows:

```powershell
choco install mkcert
mkcert -install
```

macOS:

```bash
brew install mkcert
mkcert -install
```

Linux:

```bash
sudo apt install libnss3-tools
# затем установить mkcert удобным способом для вашей системы
mkcert -install
```

### Windows + WSL2: где устанавливать mkcert

Если Docker и проект запущены из WSL, а сайт открывается в браузере Windows, есть два варианта.

Для HTTPS в Windows + WSL2 есть три разных trust store:

1. Windows trust store — нужен для браузера Windows.
2. WSL trust store — нужен для curl/mkcert в WSL.
3. PHP container trust store — нужен для Bitrix/PHP self-check.

Если сайт в браузере работает, но Bitrix пишет ошибку сокетов, возможно, PHP-контейнер не доверяет mkcert CA.

#### Вариант A - mkcert в Windows

Рекомендуется, если сайт открывается в Chrome/Yandex Browser/Edge в Windows.

1. Установить mkcert в Windows.
2. Выполнить в PowerShell от администратора:

```powershell
mkcert -install
```

3. Сгенерировать сертификат в папку проекта или использовать WSL-путь.

#### Вариант B - mkcert в WSL + импорт rootCA в Windows

1. В WSL:

```bash
sudo apt update
sudo apt install -y libnss3-tools curl
curl -L -o mkcert "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert
sudo mv mkcert /usr/local/bin/mkcert
mkcert -install
```

2. Сгенерировать сертификат:

```bash
bash docker/scripts/generate-https-cert.sh
```

3. Скопировать rootCA в Windows:

```bash
cp "$(mkcert -CAROOT)/rootCA.pem" /mnt/c/Users/<USERNAME>/Desktop/mkcert-rootCA.pem
```

4. Импортировать `mkcert-rootCA.pem` в Windows:

```text
Win + R -> certmgr.msc
Доверенные корневые центры сертификации -> Сертификаты -> Импорт
Выбрать mkcert-rootCA.pem
Перезапустить браузер
```

Если этого не сделать, `curl -vk` в WSL может показывать HTTPS 200, но браузер Windows будет ругаться на сертификат.

Путь к root CA можно вывести скриптом:

```bash
bash docker/scripts/show-mkcert-ca.sh
```

После запуска PHP-контейнера установите root CA внутрь контейнера:

```bash
bash docker/scripts/install-mkcert-ca-to-php.sh
```

Короткая последовательность для HTTPS:

```bash
# 1. Сгенерировать сертификат
bash docker/scripts/generate-https-cert.sh

# 2. Импортировать rootCA.pem в Windows, если браузер Windows не доверяет сертификату
cp "$(mkcert -CAROOT)/rootCA.pem" /mnt/c/Users/<USERNAME>/Desktop/mkcert-rootCA.pem

# 3. Установить root CA внутрь PHP-контейнера
bash docker/scripts/install-mkcert-ca-to-php.sh
```

### 2. Добавить домен в hosts

Windows:

```text
C:\Windows\System32\drivers\etc\hosts
```

Linux/macOS:

```text
/etc/hosts
```

Пример:

```text
127.0.0.1 vegaproject.loc
```

Не используйте `.dev` для локальных доменов: современные браузеры требуют HTTPS для `.dev` из-за HSTS.
Рекомендуемые зоны для локальной разработки:

- `.loc`
- `.test`

### 3. Сгенерировать сертификат

Из корня проекта:

```bash
chmod +x docker/scripts/*.sh
docker/scripts/generate-https-cert.sh
```

Скрипт берёт домен из `HTTPS_DOMAIN`, а если он не задан - из `PROJECT_DOMAIN`.
Обычно `HTTPS_DOMAIN` должен совпадать с `PROJECT_DOMAIN`.
Если в `.env` осталось `change-me.loc`, скрипт остановится и попросит указать реальный локальный домен.
Nginx не использует envsubst и остаётся с `server_name _;`.

Ручной эквивалент:

```bash
mkdir -p docker/certs
mkcert -cert-file docker/certs/local.crt -key-file docker/certs/local.key vegaproject.loc localhost 127.0.0.1 ::1
```

### 4. Запустить с HTTPS

```bash
docker compose -f docker-compose.yml -f docker-compose.https.yml up -d
```

Если `HTTPS_PORT=443`:

```text
https://vegaproject.loc
```

Если `HTTPS_PORT=8443`:

```text
https://vegaproject.loc:8443
```

### 5. Проверка

```bash
docker compose logs nginx
docker compose exec nginx nginx -t
```

Перед запуском HTTPS должны существовать файлы:

```text
docker/certs/local.crt
docker/certs/local.key
```

Не коммитьте реальные приватные ключи и сертификаты.
Файлы `docker/certs/*.key`, `docker/certs/*.crt` и `docker/certs/*.pem` должны быть в `.gitignore`.
В репозитории оставляем только `docker/certs/.gitkeep`.

### Диагностика HTTPS

Проверить, что Nginx видит HTTPS-конфиг:

```bash
docker compose exec nginx nginx -T | grep -nE "listen|ssl_certificate|443|HTTPS|REQUEST_SCHEME"
```

В конфиге должны быть строки:

```nginx
listen 443 ssl;
ssl_certificate /etc/nginx/certs/local.crt;
ssl_certificate_key /etc/nginx/certs/local.key;
fastcgi_param HTTPS on;
fastcgi_param REQUEST_SCHEME https;
```

Проверить HTTPS:

```bash
curl -vk https://PROJECT_DOMAIN:HTTPS_PORT/
```

Например:

```bash
curl -vk https://market.loc:8443/
```

Если команда возвращает `HTTP/2 200`, HTTPS на стороне Docker работает.

Проверить, что HTTP случайно не попал на HTTPS-порт:

```bash
curl -v http://market.loc:8443/
```

Ожидаемый ответ:

```text
400 The plain HTTP request was sent to HTTPS port
```

Это нормально и означает, что 8443 действительно HTTPS-порт.

## Проверка системы Bitrix в Docker

Проверить PHP-расширения для сетевых запросов:

```bash
docker compose exec php php -m | grep -Ei "curl|openssl|sockets"
```

Проверить функции sockets/streams:

```bash
docker compose exec php php -r 'var_dump(function_exists("fsockopen"), function_exists("stream_socket_client"), function_exists("socket_create"));'
```

Проверить внешний HTTPS из PHP-контейнера:

```bash
docker compose exec php php -r '$fp=@fsockopen("ssl://www.1c-bitrix.ru",443,$e,$s,10); var_dump((bool)$fp,$e,$s);'
docker compose exec php php -r 'var_dump(@file_get_contents("https://www.1c-bitrix.ru") !== false);'
```

Если внешние проверки `www.1c-bitrix.ru` успешны, sockets/curl/openssl работают.

Проверить резолв локального домена внутри PHP-контейнера:

```bash
docker compose exec php getent hosts ${PROJECT_DOMAIN}
```

`PROJECT_DOMAIN` должен резолвиться в `nginx` внутри Docker-сети через network alias.
Не добавляйте `extra_hosts: ${PROJECT_DOMAIN}:host-gateway` в `php` или `cron`: PHP начнёт ходить на хост, и самопроверка Bitrix может получить `Connection refused`, особенно если внешний HTTPS-порт не 443.

Проверить HTTPS self-request к локальному домену внутри Docker-сети:

```bash
docker compose exec php php -d display_errors=1 -r '$fp=fsockopen("ssl://PROJECT_DOMAIN",443,$e,$s,10); var_dump($fp,$e,$s);'
```

Замените `PROJECT_DOMAIN` на домен из `.env`, например `market.loc`.
Если `ssl://PROJECT_DOMAIN:443` падает с `certificate verify failed`, установите mkcert root CA внутрь PHP-контейнера:

```bash
bash docker/scripts/install-mkcert-ca-to-php.sh
```

Проверить MySQL strict mode и время:

```bash
docker compose exec db mysql -uroot -p"$DB_ROOT_PASSWORD" -e "SHOW VARIABLES LIKE 'innodb_strict_mode'; SELECT NOW(), @@global.time_zone, @@system_time_zone;"
```

Если время БД отличается на 10800 секунд, проверьте `TZ=Europe/Moscow` и `DB_TIMEZONE=+03:00` в `.env`.
Если `innodb_strict_mode=ON`, проверьте `--innodb-strict-mode=0` в `docker-compose.yml`.

## Reverse proxy (перспектива)

На этом этапе проекты запускаются через разные порты:

```
http://localhost:8081  → vegaproject
http://localhost:8082  → atomdata
```

Чтобы сайты открывались без портов — по доменным именам:

```
http://vegaproject.loc
http://atomdata.loc
```

— можно добавить обратный прокси-сервер (nginx-proxy, Traefik или собственный nginx).

Это выходит за рамки текущей сборки, но структура Docker Kit спроектирована так,
чтобы в будущем reverse proxy можно было добавить без изменения конфигурации
отдельных проектов (каждый проект уже использует уникальные `COMPOSE_PROJECT_NAME`,
`HTTP_PORT` и `container_name`).

## Предупреждения

### Локальные домены

Не используйте `.dev` для локальных доменов: современные браузеры требуют HTTPS для `.dev` из-за HSTS.
Для локальной разработки используйте `.loc` или `.test`.

### HTTPS-сертификаты

Не коммитьте реальные приватные ключи и сертификаты.
Файлы `docker/certs/*.key`, `docker/certs/*.crt` и `docker/certs/*.pem` должны быть в `.gitignore`.
В репозитории оставляем только `docker/certs/.gitkeep`.

### MySQL 5.7

Для MySQL 5.7 grants `SESSION_VARIABLES_ADMIN` и `SYSTEM_VARIABLES_ADMIN` не используются: таких грантов в MySQL 5.7 не существует.
Перед импортом дампа убедитесь, что init-скрипты и SQL из дампа совместимы с версией MySQL.

### Windows: my.cnf из bind mount

На Windows MySQL может игнорировать `my.cnf`, подключённый через bind mount,
с сообщением: `World-writable config file '/etc/mysql/conf.d/bitrix.cnf' is ignored`.

Поэтому критичные настройки (charset, collation, sql_mode) передаются через `command:`
в `docker-compose.yml` и не зависят от `my.cnf` как единственного источника.

## Типовые ошибки

### 404 на ЧПУ-страницах

Проверьте, что Nginx настроен на передачу запросов в `bitrix/urlrewrite.php`.
В `docker/nginx/default.conf` должна быть директива:

```nginx
try_files $uri $uri/ /bitrix/urlrewrite.php?$query_string;
```

### Белый экран (WSOD)

1. Проверьте логи PHP: `docker compose logs php`
2. Проверьте, что `display_errors = On` в `docker/php/php.ini`
3. Проверьте права на `bitrix/cache` и `upload`
4. Проверьте совместимость PHP-версии с проектом

### Ошибка подключения к БД

1. Проверьте, что сервис `db` запущен: `docker compose ps`
2. Проверьте логи БД: `docker compose logs db`
3. Проверьте настройки в `bitrix/php_interface/dbconn.php` — хост должен быть `db`
4. Проверьте переменные в `.env`: `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_DATABASE`

### ERR_SSL_PROTOCOL_ERROR

Проверьте:

1. `HTTPS_PORT` в `.env`.
2. Что контейнер действительно слушает порт:

```bash
docker compose ps
```

3. Что Nginx видит `listen 443 ssl`:

```bash
docker compose exec nginx nginx -T | grep -nE "listen|ssl_certificate|443"
```

4. Что сертификаты существуют:

```bash
ls -la docker/certs
```

5. Что HTTPS отвечает:

```bash
curl -vk https://PROJECT_DOMAIN:HTTPS_PORT/
```

Если `curl -vk` возвращает `HTTP/2 200`, проблема уже не в Docker/Nginx, а в доверии браузера к rootCA mkcert.

### NET::ERR_CERT_AUTHORITY_INVALID

Браузер не доверяет mkcert root CA.

Для Windows + WSL импортируйте `rootCA.pem` из WSL в Windows:

```bash
cp "$(mkcert -CAROOT)/rootCA.pem" /mnt/c/Users/<USERNAME>/Desktop/mkcert-rootCA.pem
```

Затем импортируйте файл через `certmgr.msc` в "Доверенные корневые центры сертификации".

### Bind for 0.0.0.0:443 failed: port is already allocated

Порт 443 уже занят.

Решение:

```env
HTTPS_PORT=8443
```

Перезапуск:

```bash
docker compose -f docker-compose.yml -f docker-compose.https.yml up -d --force-recreate nginx
```

### Нет прав на запись в cache/upload

```bash
bash docker/scripts/fix-permissions.sh
```

### Не импортируется дамп

1. Проверьте, что дамп не пустой и содержит корректный SQL
2. Убедитесь, что volume `db_data` не существует (удалите: `docker compose down -v` — осторожно, удалит все данные!)
3. Проверьте кодировку: дамп должен быть в UTF-8 без BOM

### Ошибка grants MySQL 8 (SYSTEM_VARIABLES_ADMIN)

Если при импорте дампа или работе Bitrix появляется:

```
Access denied; you need SYSTEM_VARIABLES_ADMIN or SESSION_VARIABLES_ADMIN
SET innodb_strict_mode=0
```

Выполните:

```bash
bash docker/scripts/fix-mysql8-grants.sh
docker compose restart php nginx
```

Скрипт берёт пользователя из `MYSQL_USER` внутри контейнера БД, то есть из `DB_USER` в `.env`.

Для MySQL 5.7 эти grants не используются.

### Ошибка кодировки

Убедитесь, что в `.env` указано:

```env
DB_CHARSET=utf8mb4
DB_COLLATION=utf8mb4_unicode_ci
```

И в `docker/db/my.cnf`:

```ini
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

### Несовместимость PHP-версии

Если проект не работает на PHP 8.4, понизьте версию до 8.2 или 8.1.
Проверьте, какие расширения требует проект — возможно, не хватает какого-то модуля.

### MySQL 5.7 не запускается на Apple Silicon

```bash
docker compose -f docker-compose.yml -f docker-compose.platform-amd64.yml up -d
```

Или замените на MariaDB, если проект совместим:

```env
DB_IMAGE=mariadb:10.6
```

### no matching manifest for linux/arm64

Выбранный Docker-образ не поддерживает Apple Silicon.
Варианты:
1. Использовать более свежий multi-arch образ
2. Запустить через `docker-compose.platform-amd64.yml`

### Bitrix работает медленно

Причины:
- медленный bind mount на Windows/macOS
- большое количество файлов в `bitrix/cache`
- проект лежит в облачной папке (iCloud, OneDrive, Dropbox)
- включена amd64-эмуляция на Apple Silicon

Решения:
- вынести кеши Bitrix в named volumes
- держать проект в `~/Projects` (не в облачной папке)
- использовать arm64-образы, где возможно
- на Windows хранить проект в WSL2, а не в `C:\`
