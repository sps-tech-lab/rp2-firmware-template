#!/usr/bin/env python3
##################################################################################################
#    _____________   ____________  ___  ____________   ____  ____  ___________ _________________ #
#   / ____/ ____/ | / / ____/ __ \/   |/_  __/ ____/  / __ \/ __ \/ ____/ ___// ____/_  __/ ___/ #
#  / / __/ __/ /  |/ / __/ / /_/ / /| | / / / __/    / /_/ / /_/ / __/  \__ \/ __/   / /  \__ \  #
# / /_/ / /___/ /|  / /___/ _, _/ ___ |/ / / /___   / ____/ _, _/ /___ ___/ / /___  / /  ___/ /  #
# \____/_____/_/ |_/_____/_/ |_/_/  |_/_/ /_____/  /_/   /_/ |_/_____//____/_____/ /_/  /____/   #
##################################################################################################
#                                         SPS :: 2025                                            #
##################################################################################################
"""
generate_presets.py

Generate a full CMakePresets.json from a CMakePresets.json.def template
by injecting a user-specified CMake generator into every configurePreset.

Usage:
  python3 generate_presets.py --def <template.def> --out <presets.json> --generator <GeneratorName>

Arguments:
  --def FILE
        Path to the template file (default: CMakePresets.json.def)

  --out FILE
        Path for the generated CMakePresets.json (default: CMakePresets.json)

  --generator NAME
        CMake generator to use for all configure presets.
        Examples: Ninja, "Unix Makefiles", "Visual Studio 17 2022"
        (this argument is required)

Examples:
  python3 generate_presets.py --def CMakePresets.json.def --out CMakePresets.json --generator Ninja
  python3 generate_presets.py --generator "Unix Makefiles"
"""

import json
import argparse
import sys
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(
        description="Generate CMakePresets.json from a .def template",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python3 generate_presets.py --def CMakePresets.json.def \\\n"
            "      --out CMakePresets.json --generator Ninja\n"
            "  python3 generate_presets.py --generator \"Unix Makefiles\""
        )
    )
    parser.add_argument(
        '--def', dest='def_file', default='CMakePresets.json.def',
        help='Path to the template file (default: CMakePresets.json.def)'
    )
    parser.add_argument(
        '--out', dest='out_file', default='CMakePresets.json',
        help='Output CMakePresets.json file (default: CMakePresets.json)'
    )
    parser.add_argument(
        '--generator', dest='generator', required=True,
        help='CMake generator to use (e.g. Ninja, "Unix Makefiles", "Visual Studio 17 2022")'
    )

    args = parser.parse_args()

    # Read and parse the template
    try:
        template_text = Path(args.def_file).read_text()
    except Exception as e:
        print(f"[⚠️ Failed to read template '{args.def_file}': {e}", file=sys.stderr)
        sys.exit(1)

    try:
        data = json.loads(template_text)
    except json.JSONDecodeError as e:
        print(f"[⚠️ Invalid JSON in template: {e}", file=sys.stderr)
        sys.exit(1)

    # Inject the chosen generator into each configurePreset
    for preset in data.get('configurePresets', []):
        preset['generator'] = args.generator

    # Write out the final CMakePresets.json
    try:
        Path(args.out_file).write_text(json.dumps(data, indent=2))
        print(f"[✅ Generated '{args.out_file}' using generator: {args.generator}")
    except Exception as e:
        print(f"[🛑 Failed to write output '{args.out_file}': {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
