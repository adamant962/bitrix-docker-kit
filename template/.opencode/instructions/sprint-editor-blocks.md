# Sprint Editor blocks

- Admin complex configs: `local/admin/sprint.editor/complex/*/config.json` + `build.json`
- Admin custom blocks: `local/admin/sprint.editor/my/*/config.json`, `script.js`, `template.html`, `style.css`
- Settings: `local/admin/sprint.editor/settings/*.php`
- Packs: `local/admin/sprint.editor/packs/*`
- Public templates: `local/templates/vega/components/sprint.editor/blocks/services/`

## Rules
- Public templates resolved by block name (`complex_example` → `complex_example.php`)
- JSON structure: `version`, `blocks`, `layouts`
- Complex blocks: nested areas with `blockName`, `dataKey`, `container`
- `complex_settings` targets nested area's `dataKey`
- Use `$this->includeBlock($block['key'])` after checking key exists
- Check empty states before reading nested arrays
- Gallery: `Sprint\Editor\Blocks\Gallery::getImages()` with resize/watermark filters
- Search indexing: `OnGetSearchIndex` handler for custom blocks
- Injection: `OnBeforeShowComponentBlocks` — injected blocks still need public templates

Full rules in `.opencode/skills/sprint-editor/SKILL.md`.
