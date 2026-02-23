#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  clang-tidy.sh -firmware [-p <build_dir>]
  clang-tidy.sh -unit-tests [-p <build_dir>]

Modes:
  --firmware     Firmware: adds --target=arm-none-eabi and ARM sysincludes, skips tests/*
  --unit-tests   Unit tests: uses host compile_commands, includes tests/*

Options:
  -p <dir>  Build directory containing compile_commands.json
EOF
}

MODE=""
BUILD_DIR=""

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --firmware) MODE="firmware"; shift ;;
    --unit-tests) MODE="unit-tests"; shift ;;
    -p)
      shift
      [[ $# -gt 0 && ! "$1" =~ ^- ]] || { echo "Error: Missing value for -p"; exit 2; }
      BUILD_DIR="$1"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown arg: $1"
      usage
      exit 2
      ;;
  esac
done


if [[ -z "${MODE}" ]]; then
  echo "Error: specify --firmware or --unit-tests"
  usage
  exit 2
fi

if [[ -z "$BUILD_DIR" ]]; then
    echo "Error: The -p [BUILD_DIR] argument is required."
    usage
    exit 2
fi

if [[ ! -f "${BUILD_DIR}/compile_commands.json" ]]; then
  echo "[clang-tidy]: No ${BUILD_DIR}/compile_commands.json found."
  echo "[clang-tidy]: Run configuration first!"
  exit 1
fi

EXTRA_ARGS=()

if [[ "${MODE}" == "firmware" ]]; then
  mapfile -t INC_DIRS < <(
    arm-none-eabi-g++ -v -E -x c++ /dev/null 2>&1 \
      | sed -n '/#include <...> search starts here:/,/End of search list./p' \
      | sed '1d;$d' \
      | sed 's/^[[:space:]]*//g' \
      | awk 'NF'
  )

  for d in "${INC_DIRS[@]}"; do
    rd="$(realpath -m "$d")"
    EXTRA_ARGS+=( "--extra-arg-before=-isystem$rd" )
  done
  EXTRA_ARGS+=( "--extra-arg-before=--target=arm-none-eabi" )

  files=$(git ls-files \
    'app/**' 'src/**' \
    '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hh' '*.hpp' '*.hxx' \
    ':!third_party/**' \
    ':!src/fonts/*.cpp' \
    ':!tests/**' \
    | grep -E '\.(c|cc|cpp|cxx|h|hh|hpp|hxx)$' || true)
fi

if [[ "${MODE}" == "unit-tests" ]]; then
  files=$(git ls-files \
    'src/**' 'tests/**' \
    '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hh' '*.hpp' '*.hxx' \
    ':!third_party/**' \
    ':!src/fonts/*.cpp' \
    | grep -E '\.(c|cc|cpp|cxx|h|hh|hpp|hxx)$' || true)
fi

# :! -> file/folder exclusion

if [[ -z "${files}" ]]; then
  echo "[clang-tidy]: No source files found"
  exit 0
fi

# shellcheck disable=SC2086
clang-tidy -p "${BUILD_DIR}" "${EXTRA_ARGS[@]}" ${files}