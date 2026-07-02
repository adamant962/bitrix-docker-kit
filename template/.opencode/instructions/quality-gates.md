# Quality gates

Required after every PHP file change:
1. `php -l <changed-file>` — syntax validation
2. `git diff -- <changed-files>` — review changes
3. `git diff --check` — whitespace/merge conflict check

For Bitrix-specific code, additionally check:
- `B_PROLOG_INCLUDED` guards present
- Output escaping (`htmlspecialcharsbx`, `CUtil::JSEscape`, safe JSON)
- No hardcoded IDs where constants exist
- Cache parameters (`CACHE_TYPE`, `CACHE_TIME`) appropriate
- No DB queries in templates
