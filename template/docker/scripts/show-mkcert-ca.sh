#!/usr/bin/env bash
set -euo pipefail

if ! command -v mkcert >/dev/null 2>&1; then
  echo "mkcert is not installed."
  exit 1
fi

CAROOT="$(mkcert -CAROOT)"

echo "mkcert CA root:"
echo "$CAROOT"
echo
echo "Root CA file:"
echo "$CAROOT/rootCA.pem"
echo
echo "For Windows browser trust:"
echo "1. Copy rootCA.pem to Windows."
echo "2. Run certmgr.msc."
echo "3. Import rootCA.pem into Trusted Root Certification Authorities."
