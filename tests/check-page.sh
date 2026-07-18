#!/usr/bin/env bash
# Usage: tests/check-page.sh <url-path> <required-string> [<required-string> ...]
# Serves the repo root on :8000, curls the given path, greps for each required string.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -m http.server 8000 --bind 127.0.0.1 >/tmp/check-page-server.log 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null' EXIT
sleep 0.5

PATH_ARG="$1"; shift
BODY=$(curl -sf "http://127.0.0.1:8000${PATH_ARG}") || { echo "FAIL: could not fetch ${PATH_ARG}"; exit 1; }

STATUS=0
for needle in "$@"; do
  if ! grep -qF -- "$needle" <<< "$BODY"; then
    echo "FAIL: '${PATH_ARG}' missing required string: $needle"
    STATUS=1
  fi
done
if [ "$STATUS" -eq 0 ]; then
  echo "PASS: ${PATH_ARG} contains all ${#@} required strings"
fi
exit $STATUS
