# Project map

- Site template: `local/templates/vega/`
- Entry point: `local/php_interface/init.php` (autoload, constants, debug, functions)
- Constants: `local/php_interface/include/constants.php`
- Helper functions: `local/php_interface/include/functions.php`
- Debug: `local/php_interface/include/debug.php` (`pr()`, `deb()`)
- PSR-4 namespace: `local/src/` (`Tanais\Vega\`)
- Bitrix core: `/bitrix/` (not tracked in git)
- Component overrides: `local/templates/vega/components/`
- Sprint Editor blocks: `local/admin/sprint.editor/` (configs) + `local/templates/vega/components/sprint.editor/blocks/services/` (public templates)
- Agents: `.opencode/agent/`
- Skills: `.opencode/skills/`
