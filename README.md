# RSKSevenProject X00TD — Kernel 4.19

Custom kernel for the **ASUS ZenFone Max Pro M1 (X00TD, Snapdragon 660)** — the 4.19 line of RSKSevenProject.

Version string: `4.19.325-RSKSevenProject`

## Features

- Linux **4.19.325** (CIP) base
- **CPU overclock to 2.2 GHz** (big cluster, forced speed bin)
- **KernelSU-Next v3.2.0-legacy (33129)** — built into the kernel, manual hook (no LKM/module loading needed)
- **SuSFS v2.3.0** — SUS_PATH / SUS_MOUNT / SUS_KSTAT, verified on-device (`ksud susfs support` → `Supported`)
- KernelSU module services auto-start correctly at boot, **including on Android 17** (this line carries a fix for the changed way Android 17 init reads `init.rc`)
- GPU untouched — stock KGSL power-level tables (per-unit sets, the highest peaking at 750 MHz); the effective GPU ceiling follows the efuse speed bin of the unit at boot — the maintainer reference unit (efuse bin 90) runs 430 MHz. An OC test build forcing the GPU to an effective 585 MHz is in preparation

## Tested

- **EvolutionX 12.2 (Android 17)** on X00TD — full bundle verified on the maintainer unit: boot, root 33129, SuSFS Supported v2.3.0, 2.2 GHz readout, module (Encore 5.2.1) auto-start.
- Earlier builds of this line were also boot-tested on Halcyon (Android 16).

## Installation

1. Download the zip from the **Releases** page and flash it in a custom recovery (AnyKernel3 installer).
2. Manage root with the **KernelSU-Next v3.2.0-legacy (33129)** Manager app. If the Manager shows an upgrade banner to v3.4.0, **do not accept it** — that release line is not compatible with this kernel.
3. No LV/NLV variants on 4.19: this single build covers every Android version.

## ⚠️ Overclock warning

The 2.2 GHz clock depends on the silicon speed bin of your individual unit. Every unit has its own ceiling — weaker units may freeze or fail to boot with this build. A **stock 1.8 GHz variant** (natural CPU and GPU bins) is in preparation as the safe fallback; if this build misbehaves on your unit, wait for that one.

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
- License: **GPLv2** (see `COPYING`). The complete source of the released build — including the KernelSU-Next integration and SuSFS — is this repository, branch `rskseven-4.19`.
