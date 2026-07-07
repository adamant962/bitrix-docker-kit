#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Env file not found: $ENV_FILE"
  exit 1
fi

ENV_VARS="$(grep -E '^(PROJECT_DOMAIN|HTTPS_DOMAIN)=' "$ENV_FILE" | xargs || true)"
if [ -n "$ENV_VARS" ]; then
  # shellcheck disable=SC2086
  export $ENV_VARS
fi

DOMAIN="${HTTPS_DOMAIN:-${PROJECT_DOMAIN:-}}"

if [ -z "$DOMAIN" ]; then
  echo "PROJECT_DOMAIN or HTTPS_DOMAIN is required in .env"
  exit 1
fi

if [ "$DOMAIN" = "change-me.loc" ]; then
  echo "HTTPS_DOMAIN/PROJECT_DOMAIN is still change-me.loc."
  echo "Set it to your local project domain first."
  exit 1
fi

if ! command -v mkcert >/dev/null 2>&1; then
  echo "mkcert is not installed."
  echo "Install mkcert first, then run this script again."
  exit 1
fi

mkdir -p docker/certs

mkcert \
  -cert-file docker/certs/local.crt \
  -key-file docker/certs/local.key \
  "$DOMAIN" localhost 127.0.0.1 ::1

echo "Certificate generated:"
echo "  docker/certs/local.crt"
echo "  docker/certs/local.key"
echo
echo "Domain: $DOMAIN"
