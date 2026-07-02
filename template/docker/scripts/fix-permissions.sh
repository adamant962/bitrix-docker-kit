#!/bin/bash
set -e

echo "Fixing permissions for Bitrix cache and upload directories..."

DIRS="\
    /var/www/html/bitrix/cache \
    /var/www/html/bitrix/managed_cache \
    /var/www/html/bitrix/stack_cache \
    /var/www/html/bitrix/html_pages \
    /var/www/html/bitrix/backup \
    /var/www/html/upload"

docker compose exec php sh -c "
    chown -R www-data:www-data $DIRS 2>/dev/null || true
    chmod -R u+rwX,g+rwX,o-rwx $DIRS 2>/dev/null || true
"

echo "Permissions fixed"
