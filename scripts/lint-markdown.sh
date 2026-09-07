#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"
config_file="${project_dir}/.markdownlint.json"

if ! command -v markdownlint >/dev/null 2>&1; then
  echo "Error: markdownlint is not installed or is not available in PATH." >&2
  exit 1
fi

if (( $# > 0 )); then
  markdownlint --config "${config_file}" "$@"
else
  markdownlint --config "${config_file}" "${project_dir}"
fi

echo "Markdown lint passed."
