#!/usr/bin/env bash
set -euo pipefail

CA_SOURCE=""

if [ -f "docker/certs/rootCA.crt" ]; then
  CA_SOURCE="docker/certs/rootCA.crt"
elif [ -f "docker/certs/rootCA.pem" ]; then
  CA_SOURCE="docker/certs/rootCA.pem"
elif command -v mkcert >/dev/null 2>&1 && [ -f "$(mkcert -CAROOT)/rootCA.pem" ]; then
  CA_SOURCE="$(mkcert -CAROOT)/rootCA.pem"
fi

if [ -z "$CA_SOURCE" ]; then
  echo "mkcert root CA not found."
  echo "Expected one of:"
  echo "  docker/certs/rootCA.crt"
  echo "  docker/certs/rootCA.pem"
  echo "  \$(mkcert -CAROOT)/rootCA.pem"
  exit 1
fi

echo "Using mkcert root CA: $CA_SOURCE"

mkdir -p docker/certs
cp "$CA_SOURCE" docker/certs/rootCA.crt

echo "Copying root CA into php container..."
docker compose cp docker/certs/rootCA.crt php:/usr/local/share/ca-certificates/mkcert-rootCA.crt

echo "Updating CA certificates inside php container..."
docker compose exec -u root php sh -lc '
if ! command -v update-ca-certificates >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates
fi

update-ca-certificates
'

DOMAIN="localhost"
if [ -f ".env" ]; then
  VALUE="$(grep -E '^PROJECT_DOMAIN=' .env | tail -n 1 | cut -d '=' -f2- || true)"
  if [ -n "$VALUE" ]; then
    DOMAIN="$VALUE"
  fi
fi

DOMAIN="${DOMAIN%\"}"
DOMAIN="${DOMAIN#\"}"
DOMAIN="${DOMAIN%\'}"
DOMAIN="${DOMAIN#\'}"

echo "Checking HTTPS self-request from php container: $DOMAIN"

docker compose exec php php -r "\$fp=@fsockopen('ssl://$DOMAIN',443,\$e,\$s,10); var_dump((bool)\$fp,\$e,\$s);"
