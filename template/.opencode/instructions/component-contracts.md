# Component contracts

Component overrides in `local/templates/vega/components/`:

| Bitrix component | Override namespace | Purpose |
|---|---|---|
| `bitrix:news` | `products` | Каталог продуктов |
| `bitrix:news` | `services` | Услуги |
| `bitrix:news` | `news` | Новости |
| `bitrix:news` | `articles` | Статьи |
| `bitrix:news` | `projects` | Проекты |
| `bitrix:news` | `amenities` | Удобства/возможности |
| `bitrix:news` | `escort` | Сопроводительные услуги |
| `bitrix:news.list` | `about.slider`, `articles_in_blog`, `functionality`, `index_articles`, `index_banners`, `index_news`, `index_our_projects`, `index_popular_list`, `news_detail_list`, `news_detail_list_stocks`, `price_cost_list`, `price_products_list`, `services_list`, `stocks`, `stocks-list`, `useful_services` | Списки элементов |
| `bitrix:news.detail` | `index_stock` | Детальная акции |
| `bitrix:menu` | `top_menu`, `footer_menu` | Меню |
| `bitrix:breadcrumb` | `breadcrumb` | Навигационная цепочка |
| `sprint.editor:blocks` | — | Множество комплексных блоков |
| `tanais:system.auth.form` | `auth`, `auth2` | Формы авторизации |

When overriding, preserve expected `$arParams`/`$arResult` shape. Escape output at template level, not in data assembly.
