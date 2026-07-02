# Bitrix Docker Kit

Универсальный набор для запуска Bitrix-проектов в Docker с поддержкой OpenCode-агентов.

## Структура

```
bitrix-docker-kit/
├── template/                    # Файлы для копирования в новый проект
│   ├── docker/                  #   конфиги Nginx, PHP, MySQL, скрипты
│   ├── docker-compose.yml       #   Compose-файл (5 сервисов)
│   ├── docker-compose.platform-amd64.yml
│   ├── .env.example             #   шаблон переменных окружения
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
