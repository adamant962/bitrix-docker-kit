#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILES=(-f docker-compose.yml)

if [ -f "docker-compose.https.yml" ]; then
  COMPOSE_FILES+=(-f docker-compose.https.yml)
fi

CA_SOURCE=""

if [ -f "docker/certs/rootCA.crt" ]; then
  CA_SOURCE="docker/certs/rootCA.crt"
elif [ -f "docker/certs/rootCA.pem" ]; then
  CA_SOURCE="docker/certs/rootCA.pem"
elif command -v mkcert >/dev/null 2>&1; then
  MKCERT_CAROOT="$(mkcert -CAROOT)"
  if [ -f "$MKCERT_CAROOT/rootCA.pem" ]; then
    CA_SOURCE="$MKCERT_CAROOT/rootCA.pem"
  fi
fi

if [ -z "$CA_SOURCE" ]; then
  echo "mkcert root CA not found."
  echo
  echo "Expected one of:"
  echo "  docker/certs/rootCA.crt"
  echo "  docker/certs/rootCA.pem"
  echo "  \$(mkcert -CAROOT)/rootCA.pem"
  echo
  echo "Run first:"
  echo "  mkcert -install"
  echo "  bash docker/scripts/generate-https-cert.sh"
  exit 1
fi

echo "Using mkcert root CA: $CA_SOURCE"

mkdir -p docker/certs
if [ "$CA_SOURCE" != "docker/certs/rootCA.crt" ]; then
  cp "$CA_SOURCE" docker/certs/rootCA.crt
fi

echo "Copying root CA into php container..."

docker compose "${COMPOSE_FILES[@]}" cp \
  docker/certs/rootCA.crt \
  php:/usr/local/share/ca-certificates/mkcert-rootCA.crt

echo "Updating CA certificates inside php container..."

docker compose "${COMPOSE_FILES[@]}" exec -u root php sh -lc '
if ! command -v update-ca-certificates >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates
fi

update-ca-certificates
'

DOMAIN="localhost"

if [ -f ".env" ]; then
  ENV_DOMAIN="$(grep -E '^PROJECT_DOMAIN=' .env | tail -n 1 | cut -d '=' -f2- || true)"
  if [ -n "$ENV_DOMAIN" ]; then
    DOMAIN="$ENV_DOMAIN"
  fi
fi

DOMAIN="${DOMAIN%\"}"
DOMAIN="${DOMAIN#\"}"
DOMAIN="${DOMAIN%\'}"
DOMAIN="${DOMAIN#\'}"

echo "Checking HTTPS self-request from php container: $DOMAIN"

docker compose "${COMPOSE_FILES[@]}" exec php php -d display_errors=1 -r "\$fp=@fsockopen('ssl://$DOMAIN',443,\$e,\$s,10); var_dump((bool)\$fp,\$e,\$s);"

echo
echo "Done."
