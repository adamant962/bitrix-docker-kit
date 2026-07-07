#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="./www"

if [ -f ".env" ]; then
  VALUE="$(grep -E '^PROJECT_ROOT=' .env | tail -n 1 | cut -d '=' -f2- || true)"
  if [ -n "$VALUE" ]; then
    PROJECT_ROOT="$VALUE"
  fi
fi

PROJECT_ROOT="${PROJECT_ROOT%\"}"
PROJECT_ROOT="${PROJECT_ROOT#\"}"
PROJECT_ROOT="${PROJECT_ROOT%\'}"
PROJECT_ROOT="${PROJECT_ROOT#\'}"

if [ ! -d "$PROJECT_ROOT" ]; then
  echo "Project root not found: $PROJECT_ROOT"
  echo "Check PROJECT_ROOT in .env"
  exit 1
fi

if ! command -v setfacl >/dev/null 2>&1; then
  echo "setfacl is not installed. Installing acl package..."
  sudo apt update
  sudo apt install -y acl
fi

echo "Fixing install permissions for: $PROJECT_ROOT"
echo "Owner: $(id -un)"
echo "Group: www-data"

sudo chown -R "$(id -u):33" "$PROJECT_ROOT"

sudo find "$PROJECT_ROOT" -type d -exec chmod 2775 {} \;
sudo find "$PROJECT_ROOT" -type f -exec chmod 664 {} \;

sudo setfacl -R -m u:"$(id -un)":rwX,g:www-data:rwX "$PROJECT_ROOT"
sudo find "$PROJECT_ROOT" -type d -exec setfacl -m d:u:"$(id -un)":rwX,d:g:www-data:rwX {} \;

echo "Checking write access from host user..."
echo "test" > "$PROJECT_ROOT/.host-write-test"
rm -f "$PROJECT_ROOT/.host-write-test"

echo "Checking write access from PHP container..."
docker compose exec php sh -lc 'touch /var/www/html/.php-write-test && rm /var/www/html/.php-write-test && echo OK'

echo "Done."
