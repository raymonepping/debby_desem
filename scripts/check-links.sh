#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is not installed or is not available in PATH." >&2
  exit 1
fi

if (( $# == 0 )); then
  set -- "${project_dir}"/docs/*.md
fi

link_file="$(mktemp "${TMPDIR:-/tmp}/debby-desem-links.XXXXXX")"
trap 'rm -f -- "${link_file}"' EXIT

grep -Eho 'https?://[^][()<>[:space:]]+' "$@" | sort -u > "${link_file}"

while IFS= read -r url; do
  [[ -n "${url}" ]] || continue
  echo "Checking ${url}"
  curl \
    --fail \
    --location \
    --max-time 20 \
    --output /dev/null \
    --retry 2 \
    --silent \
    --show-error \
    --user-agent 'debby-desem-link-check/1.0' \
    "${url}"
done < "${link_file}"

echo "External link check passed."
