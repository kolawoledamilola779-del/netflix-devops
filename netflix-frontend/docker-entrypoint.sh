#!/bin/sh
set -e

API_URL="${API_URL:-http://localhost:8080}"

printf 'window.APP_CONFIG = { API_URL: "%s" };\n' "$API_URL" > /app/build/config.js

exec serve -s build -l 3000
