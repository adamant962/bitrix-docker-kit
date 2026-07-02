---
name: bitrix-docs
description: "Official 1C-Bitrix documentation sources, search strategies, and installed source routes for classic API, D7, ORM, components, Bitrix24 REST, and project overrides."
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: bitrix
---

## When to load this skill

Load this skill when the task depends on Bitrix framework behavior: component parameters, result shape, cache, permissions, Classic API, D7, ORM, events, REST, routing, or installed module source. Do not load it for purely visual HTML/CSS review unless Bitrix behavior is involved.

## Official documentation sources

| URL | What it covers |
|---|---|
| `https://dev.1c-bitrix.ru/api_help/` | Classic Framework API (`CIBlockElement::GetList`, `CFile`, `CUser`, `CForm`, etc.) |
| `https://dev.1c-bitrix.ru/api_d7/` | D7 module APIs, namespaced classes (`\Bitrix\Main\...`, `\Bitrix\Sale\...`), events |
| `https://apidocs.bitrix24.ru/` | Bitrix24 REST methods (`crm.deal.add`, webhooks, OAuth, scopes, limits) |
| `https://dev.1c-bitrix.ru/user_help/` | Components, admin pages, user help (`bitrix:news`, `bitrix:catalog`, etc.) |
| `https://docs.1c-bitrix.ru/` | Modern framework docs, ORM concepts, DataManager, entity maps |
| `https://docs.1c-bitrix.ru/api/` | API index for unknown classes, methods, and constants — first place to look |

If the entity type is unclear or the class/method namespace is unknown, search `https://docs.1c-bitrix.ru/api/` first, then route to `api_help`, `api_d7`, `user_help`, or installed source based on the results.

## How to search by entity type

Extract the primary entity from code, then search the relevant domain:

| Entity type | Search pattern |
|---|---|
| Component | `site:dev.1c-bitrix.ru/user_help "bitrix:news"` |
| Classic API | `site:dev.1c-bitrix.ru/api_help "CIBlockElement::GetList"` |
| D7 event | `site:dev.1c-bitrix.ru/api_d7 "basket updated" "sale"` |
| D7 class | `site:dev.1c-bitrix.ru/api_d7 "SaleOrder"` |
| ORM | `site:docs.1c-bitrix.ru "DataManager"` |
| REST | `site:apidocs.bitrix24.ru "crm.deal.add"` |

If a direct URL returns 404/403, run WebSearch on official domains before declaring docs unavailable.

## Component resolution

For `IncludeComponent('vendor:name', ...)` calls, resolve documentation in this order:

1. Search component documentation by exact component name on `https://dev.1c-bitrix.ru/user_help/`
2. Inspect installed source at `/bitrix/components/vendor/name/`
3. Inspect local override at `local/templates/<site>/components/vendor/name/<template>/`

## Installed source routes

When docs are unavailable, use installed Bitrix source:

- Components: `/bitrix/components/<vendor>/<name>/component.php`, `class.php`, `.parameters.php`, `templates/.default/template.php`
- Classic/D7 modules: `/bitrix/modules/<module>/...`
- Local component overrides: `local/templates/<site>/components/<vendor>/<name>/<template>/...`
- Project code: `local/php_interface/init.php`, `local/php_interface/include/constants.php`, `local/php_interface/include/functions.php`
- Custom modules: `local/modules/`
- PSR-4 namespace: `local/src/` (`Tanais\Atomdata\`)

## Documentation usage examples

1. **News component**: before working with `bitrix:news`, read `https://dev.1c-bitrix.ru/user_help/components/content/articles_and_news/news.php`
2. **Sale events**: before using `OnSaleBasketUpdated`, read `https://dev.1c-bitrix.ru/api_d7/bitrix/sale/events/index.php` and the specific event page
3. **ORM**: before writing `*Table` queries, read `https://docs.1c-bitrix.ru/pages/orm/orm-concepts.html`
