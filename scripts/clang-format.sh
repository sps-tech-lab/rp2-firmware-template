#!/usr/bin/env bash
set -euo pipefail

CLANG_FORMAT="${CLANG_FORMAT:-clang-format}"

# Format only tracked files
files=$(git ls-files '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hh' '*.hpp' '*.hxx')

if [[ -z "${files}" ]]; then
  echo "No source files found to format."
  exit 0
fi

echo "${files}" | xargs "${CLANG_FORMAT}" -i
echo "clang-format: done"
