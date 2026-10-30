#!/usr/bin/env bash
# Append an HTTP(S) URL to targets/http.yml.
# Usage: ./scripts/add-target.sh https://example.com
# Prometheus picks the change up within ~1 minute (file-based service discovery).
set -euo pipefail

url="${1:-}"
file="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/targets/http.yml"

case "$url" in
  http://* | https://*) ;;
  *) echo "Usage: $0 <http(s)://url>" >&2; exit 1 ;;
esac
case "$url" in
  *[[:space:]\'\"]*) echo "Error: URL must not contain spaces or quotes." >&2; exit 1 ;;
esac

[ -f "$file" ] || touch "$file"

if grep -Fq "'$url'" "$file"; then
  echo "Already present: $url"
  exit 0
fi

# Make sure the file ends with a newline before appending.
if [ -s "$file" ] && [ -n "$(tail -c1 "$file")" ]; then
  echo >> "$file"
fi

printf -- "- targets: ['%s']\n" "$url" >> "$file"
echo "Added: $url  ->  $file"
echo "Prometheus reloads targets automatically within ~1 minute."
