#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"
if (( $# > 0 )); then
  epub_file="$1"
else
  epub_files=("${project_dir}"/docs/zuurdesembrood-mastergids-v*.epub)

  if (( ${#epub_files[@]} != 1 )) || [[ ! -f "${epub_files[0]}" ]]; then
    echo "Error: expected exactly one versioned master guide EPUB in docs/." >&2
    exit 1
  fi

  epub_file="${epub_files[0]}"
fi

for required_command in unzip xmllint; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    echo "Error: ${required_command} is not installed or is not available in PATH." >&2
    exit 1
  fi
done

if [[ ! -f "${epub_file}" ]]; then
  echo "Error: EPUB file not found: ${epub_file}" >&2
  exit 1
fi

unzip -tq "${epub_file}" >/dev/null

while IFS= read -r xml_file; do
  unzip -p "${epub_file}" "${xml_file}" | xmllint --noout -

  if [[ "${xml_file}" =~ EPUB/text/ch[0-9]+\.xhtml$ ]]; then
    heading_count="$(
      unzip -p "${epub_file}" "${xml_file}" |
        xmllint --xpath \
          'count(//*[local-name()="h1" or local-name()="h2" or local-name()="h3" or local-name()="h4" or local-name()="h5" or local-name()="h6"])' \
          -
    )"

    if [[ "${heading_count}" == "0" ]]; then
      echo "Error: empty or untitled EPUB chapter: ${xml_file}" >&2
      exit 1
    fi
  fi
done < <(unzip -Z1 "${epub_file}" | grep -E '\.(ncx|opf|xhtml|xml)$')

content_count="$(unzip -Z1 "${epub_file}" | grep -Ec 'EPUB/text/ch[0-9]+\.xhtml$')"

if (( content_count < 2 )); then
  echo "Error: EPUB contains fewer than two split content files." >&2
  exit 1
fi

if command -v epubcheck >/dev/null 2>&1; then
  epubcheck "${epub_file}"
elif [[ -f "${EPUBCHECK_JAR:-}" ]]; then
  java -jar "${EPUBCHECK_JAR}" "${epub_file}"
else
  echo "Note: EPUBCheck skipped; install epubcheck or set EPUBCHECK_JAR." >&2
fi

echo "EPUB validation passed (${content_count} content files)."
