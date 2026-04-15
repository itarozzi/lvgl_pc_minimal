#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DOC_DIR="${ROOT_DIR}/doc/source"
DOXYFILE="${DOC_DIR}/Doxyfile"
HTML_DIR="${DOC_DIR}/html"
LATEX_DIR="${DOC_DIR}/latex"
XML_DIR="${DOC_DIR}/xml"
PDF_DIR="${DOC_DIR}/pdf"
TMP_DOXYFILE="$(mktemp)"

cleanup() {
    rm -f "${TMP_DOXYFILE}"
}

trap cleanup EXIT

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    fi
}

require_cmd doxygen
require_cmd tectonic
require_cmd python3
require_cmd gs

if [[ ! -f "${DOXYFILE}" ]]; then
    printf 'Missing Doxygen config: %s\n' "${DOXYFILE}" >&2
    exit 1
fi

mapfile -t SOURCE_FILES < <(
    find "${ROOT_DIR}/src" \
        -path "${ROOT_DIR}/src/ui" -prune -o \
        -type f \( -name '*.c' -o -name '*.h' -o -name '*.cpp' -o -name '*.hpp' \) -print | sort
)

if [[ ${#SOURCE_FILES[@]} -eq 0 ]]; then
    printf 'No C/C++ source files found under %s\n' "${ROOT_DIR}/src" >&2
    exit 1
fi

cp "${DOXYFILE}" "${TMP_DOXYFILE}"
{
    printf '\n'
    printf 'INPUT ='
    for source_file in "${SOURCE_FILES[@]}"; do
        printf ' \134\n'
        printf '"%s"' "${source_file}"
    done
    printf '\n'
    printf 'RECURSIVE = NO\n'
    printf 'EXCLUDE =\n'
    printf 'EXCLUDE_PATTERNS =\n'
} >> "${TMP_DOXYFILE}"

rm -rf "${HTML_DIR}" "${LATEX_DIR}" "${XML_DIR}" "${PDF_DIR}" "${DOC_DIR}/markdown"
mkdir -p "${PDF_DIR}"

printf 'Generating Doxygen HTML, LaTeX, and XML output...\n'
( cd "${DOC_DIR}" && doxygen "${TMP_DOXYFILE}" )

if [[ ! -f "${LATEX_DIR}/refman.tex" ]]; then
    printf 'Expected LaTeX output not found: %s\n' "${LATEX_DIR}/refman.tex" >&2
    exit 1
fi

shopt -s nullglob
for eps_file in "${LATEX_DIR}"/*.eps; do
    pdf_file="${eps_file%.eps}.pdf"
    gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="${pdf_file}" "${eps_file}" >/dev/null
    rm -f "${eps_file}"
done
shopt -u nullglob

printf 'Building PDF with tectonic...\n'
( cd "${LATEX_DIR}" && tectonic --outdir "${PDF_DIR}" refman.tex >/dev/null )

printf '\nDocumentation exported to:\n'
printf '  HTML: %s\n' "${HTML_DIR}/index.html"
printf '  PDF: %s\n' "${PDF_DIR}/refman.pdf"
