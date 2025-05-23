#!/usr/bin/env python3
import json
import argparse
import sys
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description="Generate CMakePresets.json from .def template")
    parser.add_argument('--def',   dest='def_file', default='CMakePresets.json.def',
                        help='Path to the template file')
    parser.add_argument('--out',   dest='out_file', default='CMakePresets.json',
                        help='Output CMakePresets.json file')
    parser.add_argument('--generator', dest='generator',
                        help='CMake generator to use (e.g. "Ninja", "Unix Makefiles", "MinGW Makefiles")')
    args = parser.parse_args()

    template = Path(args.def_file).read_text()
    data = json.loads(template)

    # Determine default generator if not provided
    gen = args.generator
    if not gen:
        if sys.platform.startswith('win'):
            gen = 'MinGW Makefiles'
        elif sys.platform.startswith('darwin') or sys.platform.startswith('linux'):
            gen = 'Unix Makefiles'
        else:
            gen = 'Ninja'

    # Inject generator into each configurePreset
    for preset in data.get('configurePresets', []):
        preset['generator'] = gen

    # Write out
    out = Path(args.out_file)
    out.write_text(json.dumps(data, indent=2))
    print(f"[✅] Generated {args.out_file} using generator: {gen}")

if __name__ == '__main__':
    main()
