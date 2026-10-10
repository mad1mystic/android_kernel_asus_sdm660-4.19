# RSKSevenProject X00TD — Kernel 4.19

Custom kernel for the **ASUS ZenFone Max Pro M1 (X00TD, Snapdragon 660)** — the 4.19 line of RSKSevenProject.

Version string: `4.19.325-RSKSevenProject`

## Variants (v1.1 matrix — 2026-10-10)

| Variant | CPU max (big cluster) | GPU at boot | Zip |
|---|---|---|---|
| **Stock** | 1.8 GHz (1804800) | 430 MHz locked | `RSKSevenProject-X00TD-419-Stock-20261010.zip` |
| **OC** | 2.2 GHz (2208000) | 430 MHz locked | `RSKSevenProject-X00TD-419-OC-20261010.zip` |
| **Extreme** | 2.4576 GHz (2457600) | 430 MHz locked | `RSKSevenProject-X00TD-419-Extreme-20261010.zip` |

All three variants share the same baseline: **KernelSU-Next v3.2.0-legacy (33129)** built into the kernel with manual hook, **SuSFS v2.3.0**, and the same GPU model below. They differ only in the CPU ceiling.

## GPU — locked at boot, unlocked by module

- Every variant boots with the GPU capped at **430 MHz** (units whose GPU speed bin has no 430 MHz step boot at 370 MHz instead).
- The full GPU ladder up to **750 MHz** remains present in the kernel. To raise the cap, install the companion module **`RSKSeven-GPUControl-X00TD-v1.0.zip`** (attached to the v1.1 release) in the KernelSU-Next Manager, open the module's **WebUI**, and pick a frequency. **A reboot always restores the kernel default** — nothing is permanent.
- ⚠️ **Honest warning:** stability above 430 MHz depends on the silicon bin of your individual unit. Some units freeze under load above 430 MHz (the maintainer's own unit does). If that happens, simply reboot — the default is restored. This is a hardware lottery, not a configuration fault.

## Tested

- **EvolutionX 12.2 (Android 17)** on ASUS ZB602KL (maintainer unit): all three variants flashed and verified on-device — boot, CPU ceiling readout (1.8 / 2.2 / 2.4576 GHz), GPU lock at 430 MHz, KernelSU working, SuSFS `Supported` (v2.3.0), module services auto-starting. The GPU unlock module was exercised on-device: it raises the GPU ceiling immediately (that same unit freezes above 430 MHz under load — silicon limit, verified with CPU deliberately kept low).
- **Halcyon (Android 16)**: an earlier build of this line (the v1.0 OC kernel) was boot-tested.
- Other ROMs built on the 4.19 kernel stack have not been individually tested.

## Features

- Linux **4.19.325** (CIP) base
- Three CPU tiers — Stock 1.8 GHz, OC 2.2 GHz, Extreme 2.4576 GHz (see variant table)
- **KernelSU-Next v3.2.0-legacy (33129)** — built into the kernel, manual hook (no LKM/module loading needed)
- **SuSFS v2.3.0** — SUS_PATH / SUS_MOUNT / SUS_KSTAT, verified on-device (`ksud susfs support` → `Supported`)
- KernelSU module services auto-start correctly at boot, **including on Android 17** (this line carries a fix for the changed way Android 17 init reads `init.rc`)
- GPU default lock at 430 MHz with the full ladder to 750 MHz available through the companion module
- New installer banner for the 4.19 line

## Installation

1. Download a kernel zip from the **Releases** page and flash it in a custom recovery (AnyKernel3 installer) or FKM.
2. *(Optional)* Install `RSKSeven-GPUControl-X00TD-v1.0.zip` from the same release in the KernelSU-Next Manager to control the GPU ceiling from the module WebUI.
3. Manage root with the **KernelSU-Next v3.2.0-legacy (33129)** Manager app. If the Manager shows an upgrade banner to v3.4.0, **do not accept it** — that release line is not compatible with this kernel.
4. This line targets ROMs built on the 4.19 kernel stack. No LV/NLV variants here — one kernel covers every Android version on such ROMs.

## ⚠️ Overclock warning

CPU and GPU ceilings depend on the silicon bin of your individual unit. Every unit has its own ceiling. If a variant freezes or misbehaves on your unit, step down one variant (Extreme → OC → Stock). The GPU above 430 MHz carries the same warning — see the GPU section above. Nothing in this project can damage your phone permanently: a reboot always returns to kernel defaults.

## Special Thanks

This project stands on the hard work of others, and we are genuinely grateful:

- **[@rsuntk](https://github.com/rsuntk)** — our deepest thanks. This entire 4.19 line is built on his `android_kernel_asus_sdm660-4.19` (the VivLOS lineage kernels). His EvolutionX builds for the X00TD also gave Android 17 a home on this ageing phone — and became the very ROM this kernel was developed and proven on. None of this would exist without that groundwork.
- **[@RyuujiX](https://github.com/RyuujiX)** — heartfelt thanks for the 4.4 kernel tree that the original RSKSevenProject line was built on. This project literally began on his work; lessons and recipes from that line still run through everything we ship today.

Warm thanks as well to the **KernelSU-Next** team for the root solution, and to **SuSFS** (ShirkNeko and contributors) for the framework integrated here.

## Credits & license

- Base kernel: rsuntk — `android_kernel_asus_sdm660-4.19` (VivLOS)
- Root: KernelSU-Next v3.2.0-legacy
- Framework: SuSFS v2.3.0
- Toolchain: AOSP Clang r498229b (17.0.4)
- License: **GPLv2** (see `COPYING`). This repository carries the source of this kernel line — including the KernelSU-Next integration and SuSFS — on branch `rskseven-4.19`.
