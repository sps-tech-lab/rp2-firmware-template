#!/usr/bin/env python3
#################################################################################
#     ____  ______________     _____ _________   ______   __________  ____  __  #
#    / __ \/  _/ ____/ __ \   / ___//  _/__  /  / ____/  /_  __/ __ \/ __ \/ /  #
#   / /_/ // // /   / / / /   \__ \ / /   / /  / __/      / / / / / / / / / /   #
#  / ____// // /___/ /_/ /   ___/ // /   / /__/ /___     / / / /_/ / /_/ / /___ #
# /_/   /___/\____/\____/   /____/___/  /____/_____/    /_/  \____/\____/_____/ #
#################################################################################
# v.1.2                            SPS :: 2025                                  #
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

  -se / --size-exe

Note:
  If no flash size is provided, uses per-platform defaults

Example:
  python3 pico_size_tool.py -pl rp2040 build/…/firmware.elf
  python3 pico_size_tool.py -fl 4194304 -pl rp2350 build/…/firmware.elf
"""
import argparse
import shutil
import subprocess
import sys
import re
import json
from pathlib import Path

# -------- Defaults by platform --------
PLATFORM_DEFAULTS = {
    'rp2040': {'flash': 2 * 1024 * 1024, 'ram': 256 * 1024, 'irq': 2 * 1024},
    'rp2350': {'flash': 2 * 1024 * 1024, 'ram': 520 * 1024, 'irq': 2 * 1024},
}

# -------- Helpers --------
def which_size_candidates():
    # Prefer toolchain/gnu variants first
    for name in ("arm-none-eabi-size", "gsize", "size"):
        exe = shutil.which(name)
        if exe:
            yield exe

def supports_flag(exe, flag):
    try:
        p = subprocess.run([exe, flag], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        # GNU prints help with exit 0 for --help, BSD often exits non-zero for bad flag
        # We just check if stderr/stdout mentions the flag as known.
        text = (p.stdout or "") + (p.stderr or "")
        return flag in text or p.returncode == 0
    except Exception:
        return False

def run(cmd):
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)

def parse_gnu_sections(output):
    """
    Parse `GNU size -A` output. Expect lines like:
      .text          1234 ...
    We map: {section_name: size_bytes}
    """
    sizes = {}
    for line in output.splitlines():
        parts = line.strip().split()
        if not parts:
            continue
        name = parts[0]
        # find first integer token
        for tok in parts[1:]:
            try:
                sizes[name] = int(tok)
                break
            except ValueError:
                pass
    return sizes

def parse_bsd_sections(output):
    """
    Parse BSD/macOS `size -m <elf>` output for non-Mach-O (ELF) the tool still prints a
    Sections table. We’ll extract lines like:
      Section __TEXT,__text size 12345 ...
    or (more commonly for ELF via BSD size) a table with section names + sizes.
    To be robust, match 'size <number>' after a section/segment name.
    """
    sizes = {}
    # Try common "section <name> size <num>" style first
    sec_line = re.compile(r'^\s*(?:Section|section)\s+([^\s:]+).*?\bsize\s+(\d+)\b', re.IGNORECASE)
    for line in output.splitlines():
        m = sec_line.match(line)
        if m:
            name = m.group(1)
            sizes[name] = int(m.group(2))
            continue
        # Fallback: tokens where first token looks like a section name, followed by a size
        parts = line.strip().split()
        if len(parts) >= 2:
            # try last numeric
            for tok in parts[1:]:
                if tok.isdigit():
                    # take first token as name if it looks section-like
                    n = parts[0]
                    if n.startswith('.') or n.isidentifier():
                        sizes.setdefault(n, int(tok))
                        break
    return sizes

def detect_and_parse_sections(elf, size_exe=None):
    # Pick size executable
    exe = size_exe or next(which_size_candidates(), None)
    if not exe:
        raise RuntimeError("No 'size' tool found (tried arm-none-eabi-size, gsize, size).")

    # First try GNU-style -A
    try:
        if supports_flag(exe, "--help") and ("-A" in run([exe, "--help"])):
            out = run([exe, "-A", elf])
            secs = parse_gnu_sections(out)
            if secs:
                return secs, exe, "gnu"
        # Some GNU builds omit help text but still accept -A
        out = run([exe, "-A", elf])
        secs = parse_gnu_sections(out)
        if secs:
            return secs, exe, "gnu"
    except subprocess.CalledProcessError:
        pass

    # Try BSD/macOS -m
    try:
        out = run([exe, "-m", elf])
        secs = parse_bsd_sections(out)
        if secs:
            return secs, exe, "bsd"
    except subprocess.CalledProcessError:
        pass

    # Last resort: GNU default (not section-level, but avoids crashing)
    try:
        out = run([exe, elf])
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Failed to run '{exe}' on '{elf}':\n{e.output}") from e
    raise RuntimeError(
        f"Could not obtain per-section sizes from '{exe}'. "
        f"Install GNU binutils (arm-none-eabi-size or gsize) for detailed output."
    )

def fmt_bytes(n: int) -> str:
    return f"{n:,} B"

def sum_matching(sections: dict, patterns):
    """
    patterns: list of globs or exact names; supports simple prefixes with trailing '*'
    """
    total = 0
    for pat in patterns:
        if pat.endswith(".*"):
            prefix = pat[:-2]
            for name, val in sections.items():
                if name.startswith(prefix):
                    total += val
        else:
            total += sections.get(pat, 0)
    return total

def main():
    parser = argparse.ArgumentParser(description="Summarize memory usage by region for a Pico ELF")
    parser.add_argument('-fl', '--flash-size', type=int, help='Total FLASH region size in bytes')
    parser.add_argument('-pl', '--platform', choices=PLATFORM_DEFAULTS.keys(), default='rp2040',
                        help='Target platform name')
    parser.add_argument('-se', '--size-exe', help='Path to a specific size executable to use')
    parser.add_argument('-js', '--json', dest='json_out', help='Write JSON report to this file')
    parser.add_argument('elf', help='Path to the compiled ELF file')
    args = parser.parse_args()

    defaults = PLATFORM_DEFAULTS[args.platform]
    flash_total = args.flash_size if args.flash_size else defaults['flash']
    ram_total   = defaults['ram']
    irq_total   = defaults['irq']

    # Map sections to regions (broadened)
    FLASH_SECTIONS = [
        ".text", ".text.*",
        ".rodata", ".rodata.*",
        ".vectors",
        ".init", ".fini",
        ".init_array", ".fini_array",
        ".ARM.exidx", ".ARM.exidx.*",
        ".eh_frame", ".eh_frame.*",
        ".flash*",  # sometimes .flash_text/.flash_data
        ".boot2",   # RP2040 boot2 blob
    ]
    RAM_SECTIONS = [
        ".data", ".data.*",
        ".bss", ".bss.*",
        ".noinit", ".noinit.*",
        ".sram*",  # if linker script places named SRAM sections
    ]
    IRQ_SECTIONS = [".intlist"]

    sections, size_exe, mode = detect_and_parse_sections(args.elf, args.size_exe)

    flash_used = sum_matching(sections, FLASH_SECTIONS)
    ram_used   = sum_matching(sections, RAM_SECTIONS)
    irq_used   = sum_matching(sections, IRQ_SECTIONS)

    # JSON report
    if args.json_out:
        report = {
            "elf": args.elf,
            "platform": args.platform,
            "flash_total": flash_total,
            "ram_total": ram_total,
            "irq_total": irq_total,
            "flash_used": flash_used,
            "ram_used": ram_used,
            "irq_used": irq_used,
            "flash_used_pct": (flash_used / flash_total) if flash_total else None,
            "ram_used_pct": (ram_used / ram_total) if ram_total else None,
            "irq_used_pct": (irq_used / irq_total) if irq_total else None,
            "size_exe": size_exe,
            "mode": mode,
        }
        out_path = Path(args.json_out)
        if out_path.parent and str(out_path.parent) not in (".", ""):
            out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    # Output
    print("===================== ELF size =====================")
    print(f"Using: {size_exe}  [{mode}]")
    print(f"{'Memory region':<15}{'Used Size':>12}  {'Region Size':>12}  {'Used %':>9}")
    print("----------------------------------------------------")
    def line(label, used, total):
        pct = (used / total * 100.0) if total else 0.0
        print(f"{label+':':<15}{fmt_bytes(used):>12}  {fmt_bytes(total):>12} {pct:9.2f}%")

    line("FLASH",    flash_used, flash_total)
    line("SRAM",     ram_used,   ram_total)
    line("IDT_LIST", irq_used,   irq_total)
    print("====================================================")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"[pico_size_tool] ERROR: {e}", file=sys.stderr)
        sys.exit(1)