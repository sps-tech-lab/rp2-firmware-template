#!/usr/bin/env python3
#################################################################################
#     ____  ______________     _____ _________   ______   __________  ____  __  #
#    / __ \/  _/ ____/ __ \   / ___//  _/__  /  / ____/  /_  __/ __ \/ __ \/ /  #
#   / /_/ // // /   / / / /   \__ \ / /   / /  / __/      / / / / / / / / / /   #
#  / ____// // /___/ /_/ /   ___/ // /   / /__/ /___     / / / /_/ / /_/ / /___ #
# /_/   /___/\____/\____/   /____/___/  /____/_____/    /_/  \____/\____/_____/ #
#################################################################################
#                                  SPS :: 2025                                  #
#################################################################################
"""
Generate nice-looking developer-friendly size output table

Usage:
  python3 pico_size_tool.py [-fl FLASH_BYTES] [-pl PLATFORM] <path/to/firmware.elf>

Arguments:
  -fl / --flash-size
        Override total FLASH region size in bytes

  -pl / --platform
        Specify target platform (defaults to 'rp2040')

Note:
  If no flash size is provided, uses per-platform defaults

Example:
  python3 pico_size_tool.py -pl rp2040 build/…/firmware.elf
  python3 pico_size_tool.py -fl 4194304 -pl rp2350 build/…/firmware.elf
"""
import argparse
import subprocess
import sys

# Default sizes by platform
PLATFORM_DEFAULTS = {
    'rp2040': {'flash': 2 * 1024 * 1024, 'ram': 256 * 1024, 'irq': 2 * 1024},
    'rp2350': {'flash': 2 * 1024 * 1024, 'ram': 520 * 1024, 'irq': 2 * 1024},
}

#Parse 'size -A' output into a dict of {section_name: size_bytes}
def parse_sections(elf):

    out = subprocess.check_output(['size', '-A', elf], text=True)
    sizes = {}
    for line in out.splitlines():
        parts = line.strip().split()
        if len(parts) < 2:
            continue
        name = parts[0]
        section_size = None
        for token in parts[1:]:
            try:
                section_size = int(token)
                break
            except ValueError:
                continue
        if section_size is not None:
            sizes[name] = section_size
    return sizes

def units(n):
    #Format integer bytes with commas
    return f"{n:,} B"

def main():
    parser = argparse.ArgumentParser(
        description="Summarize memory usage by region for a Pico ELF"
    )
    parser.add_argument('-fl', '--flash-size', type=int,
                        help='Total FLASH region size in bytes')
    parser.add_argument('-pl', '--platform', choices=PLATFORM_DEFAULTS.keys(),
                        default='rp2040', help='Target platform name')
    parser.add_argument('elf', help='Path to the compiled ELF file')
    args = parser.parse_args()

    defaults = PLATFORM_DEFAULTS[args.platform]
    flash_total = args.flash_size if args.flash_size else defaults['flash']
    ram_total   = defaults['ram']
    irq_total   = defaults['irq']

    # Define which sections map to each region
    REGIONS = {
        'FLASH':    (['.text', '.rodata', '.vectors', '.init', '.fini'], flash_total),
        'SRAM':     (['.data', '.bss'], ram_total),
        'IDT_LIST': (['.intlist'], irq_total),
    }

    secs = parse_sections(args.elf)

    # Print table
    print("===================== ELF size =====================")
    print(f"{'Memory region':<15}{'Used Size':>12}  {'Region Size':>12}  {'Used %':>9}")
    print("----------------------------------------------------")
    for region, (sec_list, total) in REGIONS.items():
        used = sum(secs.get(s, 0) for s in sec_list)
        pct  = used / total * 100

        print(f"{region+':':<15}{units(used):>12}  {units(total):>12} {pct:9.2f}%")
    print("====================================================")

if __name__ == "__main__":
    main()
