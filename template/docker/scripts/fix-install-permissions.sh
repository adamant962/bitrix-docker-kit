#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-./www}"

if [ -f ".env" ]; then
  ENV_VARS="$(grep -E '^PROJECT_ROOT=' .env | xargs || true)"
  if [ -n "$ENV_VARS" ]; then
    # shellcheck disable=SC2086
    export $ENV_VARS
  fi
fi

PROJECT_ROOT="${PROJECT_ROOT:-./www}"

if [ ! -d "$PROJECT_ROOT" ]; then
  echo "Project root not found: $PROJECT_ROOT"
  exit 1
fi

echo "Fixing install permissions for: $PROJECT_ROOT"

sudo chown -R "$(id -u):33" "$PROJECT_ROOT"
sudo find "$PROJECT_ROOT" -type d -exec chmod 2775 {} \;
sudo find "$PROJECT_ROOT" -type f -exec chmod 664 {} \;

echo "Checking write access from php container..."
docker compose exec php sh -lc 'touch /var/www/html/.write-test && rm /var/www/html/.write-test && echo OK'
