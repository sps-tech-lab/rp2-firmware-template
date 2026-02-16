#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-build}"

if [[ ! -f "${BUILD_DIR}/compile_commands.json" ]]; then
  echo "[clang-tidy]: No ${BUILD_DIR}/compile_commands.json found."
  echo "[clang-tidy]: Run configuration first!"
  exit 1
fi


mapfile -t INC_DIRS < <(
  arm-none-eabi-g++ -v -E -x c++ /dev/null 2>&1 \
    | sed -n '/#include <...> search starts here:/,/End of search list./p' \
    | sed '1d;$d' \
    | sed 's/^[[:space:]]*//g' \
    | awk 'NF'
)
EXTRA_ARGS=()
for d in "${INC_DIRS[@]}"; do
  rd="$(realpath -m "$d")"
  EXTRA_ARGS+=( "--extra-arg-before=-isystem$rd" )
done
EXTRA_ARGS+=( "--extra-arg-before=--target=arm-none-eabi" )


files=$(git ls-files 'app/**' 'src/**' '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hh' '*.hpp' '*.hxx' \
  ':!third_party/**'  \
  ':!src/fonts/*.cpp' \
  || true)
# :! -> file/folder exclusion

if [[ -z "${files}" ]]; then
  echo "[clang-tidy]: No source files found"
  exit 0
fi

clang-tidy -p "${BUILD_DIR}" "${EXTRA_ARGS[@]}" ${files}
