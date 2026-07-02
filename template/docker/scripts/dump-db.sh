#!/bin/bash
set -e

OUTPUT_FILE="${1:-dump.sql}"

if [ ! -f ".env" ]; then
    echo "Warning: .env file not found, using default values"
fi

source .env 2>/dev/null || true

DB_USER="${DB_USER:-bitrix}"
DB_PASSWORD="${DB_PASSWORD:-bitrix_password}"
DB_DATABASE="${DB_DATABASE:-bitrix}"

echo "Dumping database '$DB_DATABASE' to '$OUTPUT_FILE'..."

docker compose exec db sh -c "mysqldump --default-character-set=utf8mb4 --single-transaction --routines --triggers -u\"$DB_USER\" -p\"$DB_PASSWORD\" \"$DB_DATABASE\"" > "$OUTPUT_FILE"

echo "Dump completed: $OUTPUT_FILE"
