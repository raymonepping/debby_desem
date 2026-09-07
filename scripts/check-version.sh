#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"
if (( $# > 0 )); then
  markdown_file="$1"
else
  markdown_files=("${project_dir}"/docs/zuurdesembrood-mastergids-v*.md)

  if (( ${#markdown_files[@]} != 1 )) || [[ ! -f "${markdown_files[0]}" ]]; then
    echo "Error: expected exactly one versioned master guide in docs/." >&2
    exit 1
  fi

  markdown_file="${markdown_files[0]}"
fi

expected_version="${2:-}"

if [[ ! -f "${markdown_file}" ]]; then
  echo "Error: Markdown file not found: ${markdown_file}" >&2
  exit 1
fi

for metadata_field in title subtitle author date lang description rights identifier; do
  if ! awk -v field="${metadata_field}" '
    NR == 1 && $0 == "---" { metadata = 1; next }
    metadata && $0 == "---" { exit }
    metadata && index($0, field ":") == 1 { found = 1 }
    END { exit !found }
  ' "${markdown_file}"; then
    echo "Error: required YAML metadata field is missing: ${metadata_field}" >&2
    exit 1
  fi
done

metadata_version="$(awk '
  NR == 1 && $0 == "---" { metadata = 1; next }
  metadata && $0 == "---" { exit }
  metadata && /^subtitle:[[:space:]]*Versie[[:space:]]+/ {
    sub(/^subtitle:[[:space:]]*Versie[[:space:]]+/, "")
    print
  }
' "${markdown_file}")"

filename="$(basename -- "${markdown_file}")"

if [[ ! "${filename}" =~ -v([0-9]+\.[0-9]+(\.[0-9]+)?)\.md$ ]]; then
  echo "Error: no version found in Markdown filename: ${filename}" >&2
  exit 1
fi

filename_version="${BASH_REMATCH[1]}"

if [[ -z "${metadata_version}" ]]; then
  echo "Error: no 'subtitle: Versie …' found in the YAML metadata." >&2
  exit 1
fi

if ! awk '
  NR == 1 && $0 == "---" { metadata = 1; next }
  metadata && $0 == "---" { exit }
  metadata && /^date:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*$/ {
    valid = 1
  }
  END { exit !valid }
' "${markdown_file}"; then
  echo "Error: YAML date must use the YYYY-MM-DD format." >&2
  exit 1
fi

if ! awk '
  NR == 1 && $0 == "---" { metadata = 1; next }
  metadata && $0 == "---" { exit }
  metadata && /^identifier:[[:space:]]*urn:uuid:[0-9a-fA-F-]+[[:space:]]*$/ {
    valid = 1
  }
  END { exit !valid }
' "${markdown_file}"; then
  echo "Error: YAML identifier must contain a UUID URN." >&2
  exit 1
fi

if [[ "${metadata_version}" != "${filename_version}" ]]; then
  echo "Error: metadata version ${metadata_version} does not match filename version ${filename_version}." >&2
  exit 1
fi

if [[ -n "${expected_version}" ]]; then
  expected_version="${expected_version#v}"

  if [[ "${metadata_version}" != "${expected_version}" ]]; then
    echo "Error: document version ${metadata_version} does not match expected version ${expected_version}." >&2
    exit 1
  fi
fi

echo "Version check passed (${metadata_version})."
