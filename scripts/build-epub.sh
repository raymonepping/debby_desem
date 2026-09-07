#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"
filter_file="${script_dir}/epub-filter.lua"
stylesheet="${project_dir}/css/epub.css"
cover_file="${EPUB_COVER_IMAGE:-${project_dir}/images/zuurdesemstarter-cover.png}"

if (( $# > 0 )); then
  input_file="$1"
else
  markdown_files=("${project_dir}"/docs/zuurdesembrood-mastergids-v*.md)

  if (( ${#markdown_files[@]} != 1 )) || [[ ! -f "${markdown_files[0]}" ]]; then
    echo "Error: expected exactly one versioned master guide in docs/." >&2
    exit 1
  fi

  input_file="${markdown_files[0]}"
fi

output_file="${2:-${input_file%.md}.epub}"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "Error: pandoc is not installed or is not available in PATH." >&2
  exit 1
fi

if [[ ! -f "${input_file}" ]]; then
  echo "Error: Markdown file not found: ${input_file}" >&2
  exit 1
fi

if [[ ! -f "${cover_file}" ]]; then
  echo "Error: cover image not found: ${cover_file}" >&2
  exit 1
fi

"${script_dir}/lint-markdown.sh" "${input_file}"
"${script_dir}/check-version.sh" "${input_file}"

mkdir -p -- "$(dirname -- "${output_file}")"
temp_dir="$(mktemp -d "$(dirname -- "${output_file}")/.epub-build.XXXXXX")"
temp_file="${temp_dir}/book.epub"
prepared_cover="${temp_dir}/cover.jpg"

cleanup() {
  rm -f -- "${temp_file}"
  rm -f -- "${prepared_cover}"
  rmdir -- "${temp_dir}" 2>/dev/null || true
}

trap cleanup EXIT

build_date="$(awk '
  NR == 1 && $0 == "---" { metadata = 1; next }
  metadata && $0 == "---" { exit }
  metadata && /^date:[[:space:]]*/ {
    sub(/^date:[[:space:]]*/, "")
    print
  }
' "${input_file}")"

if [[ -z "${SOURCE_DATE_EPOCH:-}" ]]; then
  if date -u -d "${build_date}" +%s >/dev/null 2>&1; then
    SOURCE_DATE_EPOCH="$(date -u -d "${build_date}" +%s)"
  else
    SOURCE_DATE_EPOCH="$(
      date -j -u -f '%Y-%m-%d %H:%M:%S' "${build_date} 00:00:00" '+%s'
    )"
  fi
  export SOURCE_DATE_EPOCH
fi

if command -v magick >/dev/null 2>&1; then
  magick "${cover_file}" \
    -auto-orient \
    -resize '1600x1600>' \
    -strip \
    -quality 85 \
    "${prepared_cover}"
elif command -v sips >/dev/null 2>&1; then
  sips \
    --setProperty format jpeg \
    --setProperty formatOptions 85 \
    --resampleHeightWidthMax 1600 \
    "${cover_file}" \
    --out "${prepared_cover}" >/dev/null
elif command -v convert >/dev/null 2>&1; then
  convert "${cover_file}" \
    -auto-orient \
    -resize '1600x1600>' \
    -strip \
    -quality 85 \
    "${prepared_cover}"
else
  echo "Error: ImageMagick or sips is required to prepare the EPUB cover." >&2
  exit 1
fi

pandoc \
  "${input_file}" \
  --from=gfm+fenced_divs \
  --to=epub3 \
  --standalone \
  --lua-filter="${filter_file}" \
  --css="${stylesheet}" \
  --epub-cover-image="${prepared_cover}" \
  --split-level=2 \
  --toc \
  --toc-depth=3 \
  --output="${temp_file}"

"${script_dir}/validate-epub.sh" "${temp_file}"
mv -f -- "${temp_file}" "${output_file}"

echo "EPUB created: ${output_file}"
