#!/usr/bin/env python3
# CI guard: a pernet_operations object must never live in __init.
#
# Why this exists: net/ipv4/ping.c used to declare its pernet_operations object as
# `static __initdata`, which put it in .init.data. register_pernet_subsys() links it
# into the global pernet_list, and free_initmem() then FREES AND UNMAPS that whole
# region (arch/arm64/mm/init.c -> unmap_kernel_range). Nothing on Android walks
# pernet_list during boot, so the damage stayed invisible until the first
# unshare(CLONE_NEWNET) -- i.e. the first Droidspaces/LXC container -- which read
# ops->id from unmapped memory, oopsed, and rebooted the phone. Every container
# start died that way until 2026-10-18.
#
# Why not System.map: CONFIG_KALLSYMS_ALL is off on this kernel, so System.map only
# carries GLOBAL data symbols (jiffies and init_net are present; ping_v4_net_ops is
# static and is not). Asserting against System.map therefore silently skips the one
# object that matters -- which is precisely how this bug shipped. Checking the bytes
# that actually get flashed is the only honest version of this gate.
#
# How: arm64 keeps .rela.dyn inside the Image, as records of
#     { u64 r_offset, u64 r_info, s64 r_addend }
# A relocation whose addend equals a known symbol address is the one materialising
# &that_symbol. ping_v4_proc_init_net / ping_v4_proc_exit_net are static *functions*,
# so they ARE in System.map and give two independent anchors. In
# struct pernet_operations, .init sits at +0x10 (struct list_head is 16 bytes) and
# .exit another 0x10 further on, so a relocation pair with exactly that spacing is
# the ops object, and the object's address is r_offset(.init) - 0x10.
#
# Measured on real builds:
#     2026-10-17 (buggy)  0xffffff8009c880a8  inside [__init_begin .. __init_end)
#     2026-10-18 (fixed)  0xffffff800a261348  in .data, past __init_end
#
# Usage: check_pernet_ops.py <Image> <System.map>

import struct
import sys

PERNET_OPS_INIT_FIELD = 0x10  # offsetof(struct pernet_operations, init)
EXIT_FIELD_SPACING = 0x10     # offsetof(.exit) - offsetof(.init) in this tree


def load_symbols(path):
    syms = {}
    with open(path) as fh:
        for line in fh:
            parts = line.split()
            if len(parts) == 3:
                syms[parts[2]] = int(parts[0], 16)
    return syms


def reloc_fields(data, addr):
    """r_offset of every relocation whose addend is `addr`."""
    needle = struct.pack("<Q", addr)
    offsets, i = [], data.find(needle)
    while i != -1:
        if i >= 16:  # r_offset @ -16, r_info @ -8, addend @ 0
            offsets.append(struct.unpack_from("<Q", data, i - 16)[0])
        i = data.find(needle, i + 1)
    return offsets


def main(image_path, map_path):
    syms = load_symbols(map_path)
    required = ("__init_begin", "__init_end",
                "ping_v4_proc_init_net", "ping_v4_proc_exit_net")
    missing = [s for s in required if s not in syms]
    if missing:
        print("::error::System.map is missing %s" % ", ".join(missing))
        return 1

    init_begin, init_end = syms["__init_begin"], syms["__init_end"]
    with open(image_path, "rb") as fh:
        data = fh.read()

    init_fields = reloc_fields(data, syms["ping_v4_proc_init_net"])
    exit_fields = reloc_fields(data, syms["ping_v4_proc_exit_net"])
    pairs = [(f, e) for f in init_fields for e in exit_fields
             if e - f == EXIT_FIELD_SPACING]
    if not pairs:
        print("::error::could not locate ping_v4_net_ops in the Image: no relocation "
              "pair %d bytes apart" % EXIT_FIELD_SPACING)
        print("  ping_v4_proc_init_net relocations at: %s"
              % [hex(x) for x in init_fields[:6]])
        print("  ping_v4_proc_exit_net relocations at: %s"
              % [hex(x) for x in exit_fields[:6]])
        return 1

    obj = pairs[0][0] - PERNET_OPS_INIT_FIELD
    print("ping_v4_net_ops object = 0x%x   __init region = [0x%x .. 0x%x)"
          % (obj, init_begin, init_end))
    if init_begin <= obj < init_end:
        print("::error::ping_v4_net_ops (0x%x) is inside __init: free_initmem() "
              "frees AND unmaps that region, so the first unshare(CLONE_NEWNET) "
              "(any Droidspaces/LXC container) would oops and reboot the phone"
              % obj)
        return 1
    print("OK: ping_v4_net_ops is outside __init, in permanent memory")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: check_pernet_ops.py <Image> <System.map>")
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2]))
