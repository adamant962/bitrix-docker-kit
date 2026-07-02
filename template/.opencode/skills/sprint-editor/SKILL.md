---
name: sprint-editor
description: "Rules and project conventions for reviewing and implementing Sprint Editor blocks in this Bitrix project: complex configs, build files, settings, public templates, indexing, and component integration."
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: sprint-editor
---

## Primary project paths
- `local/admin/sprint.editor/complex/*/config.json`
- `local/admin/sprint.editor/complex/*/build.json`
- `local/admin/sprint.editor/blocks/*/config.json`
- `local/admin/sprint.editor/blocks/*/script.js`
- `local/admin/sprint.editor/blocks/*/template.html`
- `local/admin/sprint.editor/blocks/*/style.css`
- `local/admin/sprint.editor/settings/*.php`
- `local/admin/sprint.editor/settings/*.css`
- `local/admin/sprint.editor/packs/*`
- `local/templates/vega/components/sprint.editor/blocks/services/*.php`
- `local/php_interface/init.php`
- `local/php_interface/include/functions.php`

## Sprint Editor rules
- Public templates for `sprint.editor:blocks` are resolved by block name. A block named `complex_example` needs a public template such as `complex_example.php` in the project template override.
- The editor JSON structure uses `version`, `blocks`, and `layouts`. Blocks have `name`, `layout`, optional `settings`, and block-specific data.
- Complex blocks use nested areas with `blockName`, `dataKey`, and `container`.
- `complex_settings` must target the nested area's `dataKey`, not just the nested block type.
- Container restrictions are configured through `complex_settings` and `blocks` with hidden values.
- Public templates should call nested blocks through `$this->includeBlock($block['key'])` only after checking that the nested key exists and is usable.
- User settings may define `block_settings`, `block_enabled`, `block_titles`, `block_configs`, `layout_classes`, and `layout_defaults`.
- Toolbar customization uses settings files with `block_toolbar` for block groups and `block_configs` for button HTML, title, hint, and description overrides.
- A settings PHP file can have a same-named CSS file in `local/admin/sprint.editor/settings/`; that CSS is loaded in the editor admin area, but public pages need explicit CSS connection.
- Trumbowyg text styles are commonly configured through a hidden `block_settings.text.csslist` value map and matching CSS classes.
- Replacing the standard text editor with CKEditor means overriding `local/admin/sprint.editor/blocks/text/`, loading CKEditor through block `config.json`, initializing it in `script.js`, and keeping the saved data shape compatible (`value`).
- Gallery watermarks can be applied in public gallery templates through `Sprint\Editor\Blocks\Gallery::getImages()` resize filters for both preview and detail images.
- Custom block content may need a `sprint.editor` `OnGetSearchIndex` handler if it should participate in Bitrix search.
- Blocks can be injected before rendering through `OnBeforeShowComponentBlocks`; injected block names still need public templates.
- The Sprint Editor `Limits` wiki page documents article size limits, not block count limits: large editor content stored in iblock properties can hit the Bitrix `text` column limit unless the project uses separate property storage and the Sprint Editor longtext conversion.

## When reviewing an existing block
- Match admin config/build fields against PHP template usage.
- Check that every template field is defined in admin config or intentionally derived.
- Check that every admin field is rendered or intentionally admin-only.
- Check nested complex blocks and containers for correct `dataKey` usage.
- Check output escaping for text, attributes, URLs, file names, and image alt text.
- Check empty states before reading nested arrays, looping over items, or including nested blocks.
- Check consistency of block names, file names, CSS classes, and project naming patterns.
- Check whether frontend styling already exists in the template CSS/Less layer before recommending new styles.
- Check whether block content should be indexed for Bitrix search.
- For gallery templates, check `Gallery::getImages()` options, resize dimensions, watermark filters, alt/description output, and empty image handling.
- For text editor customization, check that admin editor overrides preserve the original data structure expected by public templates.
- For settings-driven styles, check that admin-only CSS is also available in public output when rendered classes affect frontend content.
- For toolbar customization, check that `block_toolbar` references real block names and that custom button HTML uses safe local asset paths.

## When designing a new block
- Propose the minimal required admin files and public template file.
- Define field names, expected data shape, nested block keys, and empty-state behavior.
- Reuse existing project block patterns where possible.
- Prefer simple PHP templates and existing project helpers.
- Avoid inventing Sprint Editor APIs. If an API is not visible in existing code or documented Sprint Editor behavior, call it out as an assumption.
- If the task is only editor UX, prefer settings-based changes (`block_settings`, `block_configs`, `block_toolbar`, same-named settings CSS) before proposing a full custom block.
- If changing the standard `text` block, preserve the stored `value` field unless the user explicitly accepts a content migration.

## Standard blocks vs complex blocks

Sprint Editor content can use both standard blocks and project custom complex blocks.

Standard blocks are located in:
- `/bitrix/admin/sprint.editor/blocks/*`
- `/bitrix/components/sprint.editor/blocks/templates/.default/*`

Local standard block overrides may exist in:
- `local/admin/sprint.editor/blocks/*`
- `local/templates/vega/components/sprint.editor/blocks/services/*`

Project complex blocks are located in:
- `local/admin/sprint.editor/complex/*`
- `local/templates/vega/components/sprint.editor/blocks/services/complex_*.php`

When filling content:
- prefer standard blocks for simple headings, paragraphs, lists, images, galleries, files, and tables;
- use complex blocks for branded sections, sliders, tabs, accordions, cards, and project-specific layouts;
- do not force all content into `complex_*`;
- do not embed images as inline HTML inside text fields when image/gallery/file blocks are available;
- dry-run must show why each complex block was chosen instead of a standard block.

To discover all available blocks: `php local/scripts/fill-sprint-content.php --registry`.

## Content filling / property import rules
- `element_id`, `iblock_id`, `property_code` and `content_source` always come from the user request.
- Before saving, verify that the target property has `USER_TYPE = sprint_editor`.
- JSON must be validated by reading the raw `~VALUE` back after save, not the HTML-escaped `VALUE`.
- Use `Sprint\Editor\Structure\Structure` and `toJson()` where possible. If building the array manually, validate `version`, `blocks`, and `layouts`.
- Images must not be stored as local paths or plain numeric IDs. Image fields must contain a full file array with `ID`, `SRC`, `ORIGIN_SRC`, `WIDTH`, `HEIGHT`.
- For gallery blocks use `images[]`, for file downloads use `files[]`.
- Before inserting an image into a complex block field, inspect `config.json`, `build.json`, and the public template to confirm the expected field shape.
- An empty `file: []` in an expected image field is a failure. The task is not complete until all source images appear in the correct JSON structure.
- Before `replace` mode, create a backup of the current property value.
- `dry-run` mode is required before any save that involves images or files.
- After saving, read the property back and verify: JSON decodes, version=2, blocks non-empty, layouts non-empty, all image fields populated, no inline `<img>` in text fields unless permitted, standard blocks used where appropriate, UTF-8 valid.
- PHP utility for content filling: `local/scripts/fill-sprint-content.php`.
- Dedicated subagent: `sprint-editor-content-filler` for filling tasks.
