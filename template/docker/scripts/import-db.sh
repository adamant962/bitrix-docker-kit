#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <dump-file.sql>"
    echo "Example: $0 dump.sql"
    exit 1
fi

DUMP_FILE="$1"

if [ ! -f "$DUMP_FILE" ]; then
    echo "Error: file '$DUMP_FILE' not found"
    exit 1
fi

if [ ! -f ".env" ]; then
    echo "Warning: .env file not found, using default values"
fi

source .env 2>/dev/null || true

DB_USER="${DB_USER:-bitrix}"
DB_PASSWORD="${DB_PASSWORD:-bitrix_password}"
DB_DATABASE="${DB_DATABASE:-bitrix}"

echo "Importing '$DUMP_FILE' into database '$DB_DATABASE'..."

docker compose exec -T db sh -c "mysql -u\"$DB_USER\" -p\"$DB_PASSWORD\" \"$DB_DATABASE\"" < "$DUMP_FILE"

echo "Import completed successfully"
