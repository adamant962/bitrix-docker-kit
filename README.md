# Bitrix Docker Kit

Универсальный набор для запуска Bitrix-проектов в Docker с поддержкой OpenCode-агентов.

## Структура

```
bitrix-docker-kit/
├── template/                    # Файлы для копирования в новый проект
│   ├── docker/                  #   конфиги Nginx, PHP, MySQL, скрипты
│   │   ├── nginx/https.conf     #   опциональный HTTPS server block
│   │   ├── db/init/01-mysql8-grants.sh
│   │   ├── scripts/generate-https-cert.sh
│   │   ├── scripts/install-mkcert-ca-to-php.sh
│   │   ├── scripts/show-mkcert-ca.sh
│   │   ├── scripts/fix-install-permissions.sh
│   │   ├── php/msmtprc
│   │   └── certs/.gitkeep       #   каталог для локальных сертификатов
│   ├── docker-compose.yml       #   Compose-файл (5 сервисов)
│   ├── docker-compose.https.yml #   override для HTTPS
│   ├── docker-compose.platform-amd64.yml
│   ├── .env.example             #   шаблон переменных окружения
│   ├── .gitignore               #   исключения локальных сертификатов
│   ├── .dockerignore
│   ├── README.Docker.md         #   документация по Docker
│   ├── opencode.json            #   конфигурация OpenCode
│   ├── AGENTS.md.example        #   шаблон AGENTS.md с плейсхолдерами
│   └── .opencode/               #   агенты, команды, инструкции, навыки
├── examples/                    # Примеры .env для разных версий PHP/БД
├── opencode-examples/           # Примеры AGENTS.md для разных проектов
│   ├── AGENTS.vega.md           #   пример реального проекта (vega)
│   ├── AGENTS.generic.md        #   generic-шаблон с пустыми секциями
│   └── AGENTS.empty.md          #   только заголовки секций
└── README.md                    # Этот файл
```

## Docker runtime

Docker — среда выполнения Bitrix. Каждый проект получает изолированные контейнеры
nginx, php, db, cron, adminer. Подробнее: `template/README.Docker.md`.

Для установки Bitrix через `bitrixsetup.php` есть отдельный скрипт прав, который сохраняет доступ и PHP-контейнеру, и пользователю WSL/IDE:

```bash
bash docker/scripts/fix-install-permissions.sh
```

### Быстрые команды

```bash
# HTTP
docker compose up -d

# HTTPS
bash docker/scripts/generate-https-cert.sh
docker compose -f docker-compose.yml -f docker-compose.https.yml up -d
bash docker/scripts/install-mkcert-ca-to-php.sh

# Проверка Nginx
docker compose exec nginx nginx -t

# Перезапуск Nginx
docker compose restart nginx
```

HTTPS включается только через `docker-compose.https.yml`; базовый HTTP-режим не меняется.
Для локальных сертификатов используйте `mkcert` и каталог `docker/certs`.
Не коммитьте реальные `*.crt`, `*.key`, `*.pem`; в репозитории остаётся только `docker/certs/.gitkeep`.

Не используйте `.dev` для локальных доменов из-за HSTS. Рекомендуемые зоны: `.loc`, `.test`.

### HTTPS в Windows + WSL2

Если проект запускается в WSL, а сайт открывается в браузере Windows, после `mkcert -install` в WSL нужно импортировать `rootCA.pem` в Windows trust store.
Иначе Docker/Nginx может корректно отдавать HTTPS, но браузер будет ругаться на сертификат.

Подробности: `template/README.Docker.md`, раздел “Windows + WSL2: где устанавливать mkcert”.

### Bitrix system check

Для успешной проверки системы Bitrix kit настраивает:

- `sockets`, `curl`, `openssl` в PHP
- HTTPS через `mkcert`
- trust root CA внутри PHP-контейнера
- `PROJECT_DOMAIN` как network alias nginx-контейнера
- `innodb_strict_mode=0`
- синхронизацию timezone PHP/MySQL
- install-friendly таймауты Nginx/PHP
- права для установки через `fix-install-permissions.sh`

Подробности: `template/README.Docker.md`.

### HTTPS and mail for Bitrix system check

Kit supports local Bitrix system check with:

- mkcert HTTPS certificates
- nginx network alias for `PROJECT_DOMAIN`
- `install-mkcert-ca-to-php.sh` for trusting mkcert root CA inside PHP container
- Mailpit + msmtp for local `mail()` testing
- no real outbound email delivery required

Подробности: `template/README.Docker.md`.

## OpenCode agents

OpenCode — инструмент разработчика, **запускается на хосте** (не как Docker-сервис).

### Установка в новый проект

Скопируйте файлы в корень Bitrix-проекта:

```bash
cp /path/to/bitrix-docker-kit/template/opencode.json ./opencode.json
cp -R /path/to/bitrix-docker-kit/template/.opencode ./.opencode
cp /path/to/bitrix-docker-kit/template/AGENTS.md.example ./AGENTS.md

# или если kit лежит рядом с проектом:
# cp ../bitrix-docker-kit/template/opencode.json ./opencode.json
# cp -R ../bitrix-docker-kit/template/.opencode ./.opencode
# cp ../bitrix-docker-kit/template/AGENTS.md.example ./AGENTS.md
```

### Настройка AGENTS.md

Откройте `AGENTS.md` и заполните секции под свой проект:

- `PROJECT_IDENTITY` — namespace, название проекта
- `TEMPLATE_PATHS` — пути к шаблону и компонентам
- `IBLOCK_CONSTANTS` — ID инфоблоков вашего сайта
- `WEB_FORMS` — формы Bitrix24
- `COMPONENT_OVERRIDES` — переопределённые компоненты
- `SPRINT_EDITOR_BLOCKS` — блоки Sprint Editor

Готовые примеры для справки: `opencode-examples/`.

### О примерах AGENTS.vega.md

`AGENTS.vega.md` — пример конкретного проекта. **Не копируйте его в другой проект
без редактирования**: namespace, пути шаблона, ID инфоблоков, формы и Sprint Editor-блоки
уникальны для каждого сайта.

### Безопасность

API-ключи не храните в репозитории. Используйте переменные окружения
(в `opencode.json` уже настроено: `{env:OPENMODEL_API_KEY}`).

### Docker и OpenCode — независимые слои

Docker Kit не требует OpenCode для работы, и наоборот.
Вы можете использовать только Docker, только OpenCode, или оба инструмента вместе.
