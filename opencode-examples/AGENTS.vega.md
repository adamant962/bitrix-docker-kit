# Project conventions for OpenCode agents

# ⚠️ ВНИМАНИЕ: это пример конкретного проекта (vega).
# Не используйте этот файл для других сайтов без редактирования:
#   - namespace_psr4
#   - путей шаблона (TEMPLATE_PATHS)
#   - ID инфоблоков (IBLOCK_CONSTANTS)
#   - форм (WEB_FORMS)
#   - Sprint Editor-блоков (SPRINT_EDITOR_BLOCKS)
#   - компонентов (COMPONENT_OVERRIDES)

## PROJECT_IDENTITY
- project: vega
- site_template: vega
- namespace_psr4: Tanais\Vega
- namespace_src: local/src

## TEMPLATE_PATHS
- site_template: local/templates/vega
- components: local/templates/vega/components
- sprint_editor_public: local/templates/vega/components/sprint.editor/blocks/services
- sprint_editor_admin_complex: local/admin/sprint.editor/complex
- sprint_editor_admin_custom: local/admin/sprint.editor/my
- sprint_editor_settings: local/admin/sprint.editor/settings
- scripts: local/scripts

## PHP
- init: local/php_interface/init.php
- constants: local/php_interface/include/constants.php
- functions: local/php_interface/include/functions.php
- debug: local/php_interface/include/debug.php

## FRONTEND_ASSETS
- css_dir: local/templates/vega/css
- js_dir: local/templates/vega/js
- main_css: style.css, main.css, font-rubik.css, fancybox.css, animate.min.css
- main_js: main.js, header.js, metric.js, marquee.js
- cdn_jquery: 3.5.1
- cdn_swiper: true
- cdn_slick: true
- cdn_fancybox: true
- cdn_popper_tippy: true
- has_npm: false
- has_bundler: false

## IBLOCK_CONSTANTS
- IBLOCK_ID_1C_PRODUCTS: 48
- IBLOCK_ID_SERVICES_1C: 25
- IBLOCK_ID_PRICE_SERVICES_1C: 57
- IBLOCK_ID_NEWS: 59
- IBLOCK_ID_ARTICLES: 9
- IBLOCK_ID_BLOG: 65
- IBLOCK_ID_AMENITIES: 60
- IBLOCK_ID_BANNER_INDEX: 27
- IBLOCK_ID_PROJECTS: 30
- IBLOCK_ID_STOCKS: 52
- IBLOCK_ID_OUR_PROJECTS: 56
- IBLOCK_ID_POKUPKA_I_LITSENZIROVANIE_SISTEM_1S: 53
- IBLOCK_ID_ESCORT_SERVICES_1C: 63
- HIGHLOADBLOCK_TYPE_ID: 1
- HIGHLOADBLOCK_TYPE_SERVICES_ID: 2

## WEB_FORMS
- type: bitrix24
- forms: click/139, click/191, click/150, click/149, inline/204

## GIT_CONVENTIONS
- branch: master (direct commits)
- prefixes: edit, add, modify

## QUALITY_GATES
- php_lint: php -l <file>
- diff_review: git diff -- <file>
- whitespace_check: git diff --check
- check_b_prolog: true
- check_escaping: htmlspecialcharsbx, CUtil::JSEscape, safe JSON
- check_hardcoded_ids: true
- check_cache_params: true
- check_db_in_templates: true

## COMPONENT_OVERRIDES
- bitrix:news: products, services, news, articles, projects, amenities, escort
- bitrix:news.list: about.slider, articles_in_blog, functionality, index_articles, index_banners, index_news, index_our_projects, index_popular_list, news_detail_list, news_detail_list_stocks, price_cost_list, price_products_list, services_list, stocks, stocks-list, useful_services
- bitrix:news.detail: index_stock
- bitrix:menu: top_menu, footer_menu
- bitrix:breadcrumb: breadcrumb
- tanais:system.auth.form: auth, auth2

## SPRINT_EDITOR_BLOCKS
- complex: complex_callback_block, complex_duo_block_list, complex_duo_block_lists_text, complex_duo_block_text_image, complex_duo_block_text_list_links, complex_duo_block_text_pic, complex_duo_block_text_pic_2, complex_duo_block_text_pic_with_link, complex_duo_text_blocks, complex_five_blocks, complex_four_blocks_with_title_subtext, complex_price, complex_prod_duo_block_with_title, complex_three_blocks_with_title, complex_title_with_teasers, complex_top_banner_articles, complex_two_block_with_background
- custom: my_anchor, my_complex_2textfield, my_htag, my_layered, my_lists_link, my_lists_text, my_quote, my_teaser, my_textfield, my_tinymce

## SCRIPTS
- fill_sprint_content: local/scripts/fill-sprint-content.php
