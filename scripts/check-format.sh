#!/usr/bin/env bash
set -euo pipefail

CLANG_FORMAT="${CLANG_FORMAT:-clang-format}"

# Check only tracked files
files=$(git ls-files '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hh' '*.hpp' '*.hxx')

if [[ -z "${files}" ]]; then
  echo "No source files found to check."
  exit 0
fi

# -n = dry run, -Werror = fail if formatting differs
echo "${files}" | xargs "${CLANG_FORMAT}" -n -Werror
echo "clang-format: OK"
