# TWRP device tree — Sony Xperia XA1 (`hinoki`)

TWRP **3.7.1** device tree for the Sony Xperia XA1, built from the current
`twrp-12.1` branch of the TeamWin minimal manifest.

This replaces the abandoned Android 8.1 / TWRP 3.2-era tree that the XA1 has
been stuck on. It is a rewrite rather than a rebase — the old tree carried
several values that were simply wrong for this phone (see
[What changed](#what-changed-versus-the-old-tree)).

| | |
|---:|:---|
| Codename | `hinoki` |
| Models | G3121, G3123, G3125, G3112, G3116 (XA1 / XA1 Dual) |
| SoC | MediaTek MT6757 (Helio P20), 8× Cortex-A53 |
| GPU | Mali-T880 MP2 |
| RAM / storage | 3 GB / 32 GB + microSD |
| Display | 5.0" 720×1280 IPS |
| Kernel | 4.4.83, arm64 |
| Launched | April 2017, Android 7.0 (final stock: 8.0) |
| Layout | A-only, non-dynamic, non-system-as-root, FDE |

## Which TWRP is "latest"

TWRP 3.7.1 (21 Feb 2024) is the newest release. It is published from two live
source branches, and the branch decides which Android base the recovery is
compiled against, not the version number:

| Branch | Produces | Android base |
|:--|:--|:--|
| `twrp-11` | 3.7.1_11 | 11 |
| **`twrp-12.1`** | **3.7.1_12** | **12.1 (`android-12.1.0_r4`)** |
| `twrp-14` / `twrp-14.1` | 3.7.1_14 | 14 / 14.1 |

This tree targets **`twrp-12.1`**. The 14.x branches exist for Android 14/15-era
hardware — GKI kernels, `vendor_boot`, FBE v2, dynamic partitions — none of which
`hinoki` has. On a 2017 MT6757 with a 4.4 kernel, an fbdev framebuffer and
full-disk encryption, `twrp-12.1` is the newest branch whose defaults actually
match the device. The build workflow still lets you pick `twrp-14.1` if you want
to experiment; expect to fix things up.

## Building

Measured on the CI run below (4-core GitHub-hosted runner, `twrp-12.1`):

| | |
|---:|:---|
| Shallow source tree after `repo sync` | **34 GB** |
| `repo sync` wall time | 4m40s |
| `mka recoveryimage` wall time | **46m51s** |

Allow ~60 GB to cover the tree plus `out/`. The 34 GB is measured; the rest is
headroom, since a `recoveryimage`-only build does not populate `out/` anywhere
near as heavily as a full ROM.

```bash
mkdir -p ~/twrp && cd ~/twrp
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1 --git-lfs
repo sync -c -j"$(nproc --all)" --force-sync --no-clone-bundle --no-tags

git clone https://github.com/Ellosan/TWRP-LATEST-HINOKI.git device/sony/hinoki

export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch twrp_hinoki-eng
mka recoveryimage
```

The image lands at `out/target/product/hinoki/recovery.img`.

### Building in CI

`.github/workflows/build-twrp.yml` does the whole thing on a GitHub-hosted
runner: **Actions → Build TWRP for hinoki → Run workflow**. It frees up the
runner disk first (the stock image does not have room for an AOSP tree), syncs
the manifest branch you pick, drops this repo into `device/sony/hinoki` and
uploads `recovery.img` plus a `SHA256SUMS` as a build artifact.

### Verified build

This tree builds clean. Run
[#3](https://github.com/Ellosan/TWRP-LATEST-HINOKI/actions/runs/30281029316)
(`twrp-12.1`, `twrp_hinoki-eng`, commit `c5b5b51`):

```
recovery.img          33 MB   e05d5192e8bc7925051569a76a68a8e1a00bc4f5bc9b3a164541a538dbc8ec56
ramdisk-recovery.img  24 MB   4d3fff109c8512d66adfb9d0f79cf3a4fc5b4e33b55f93d3b99873715c14e1a5
```

33 MB against a 40 MiB (41943040-byte) `recovery` partition, so
`assert-max-image-size` passes with room to spare — which also corroborates the
partition size taken from the `mt6757-common` tree.

Building clean is not the same as booting. See
[Known limitations](#known-limitations).

## Flashing

The bootloader must be unlocked (`fastboot oem unlock`, after getting an unlock
code from Sony's developer site — note this wipes the device and permanently
disables the camera's DRM-backed processing).

```bash
adb reboot bootloader
fastboot flash recovery recovery.img
fastboot reboot
```

`hinoki` flashes to the **`recovery`** partition. Sony's Qualcomm phones use
`FOTAKernel`; this one does not have that partition at all, despite what the
previous device tree claimed.

To enter recovery: power off, then hold **Volume Down + Power** until the phone
vibrates.

## Layout of this tree

```
AndroidProducts.mk              product/lunch registration
twrp_hinoki.mk                  product definition (twrp_hinoki)
device.mk                       product packages and recovery ramdisk wiring
BoardConfig.mk                  board + TWRP configuration
recovery.fstab                  partition map (TWRP fstab v2, v1 for removables)
system.prop                     device identification properties
prebuilt/kernel                 stock 4.4.83 Image.gz with appended MT6757 DTB
recovery/root/                  files copied verbatim into the recovery ramdisk
  init.recovery.mt6757.rc         MTK charger mode, backlight/vibrator perms
  ueventd.mt6757.rc               by-name block device permissions
.github/workflows/build-twrp.yml  CI build
```

### About the prebuilt kernel

`prebuilt/kernel` is the stock kernel blob lifted out of the XA1 boot image: a
gzip-compressed `Image` (25.5 MB uncompressed) with the MT6757 device tree blob
appended after the end of the gzip stream (127 KB, magic `d00dfeed` at offset
9527094). Do **not** decompress, recompress or strip it — the appended DTB would
be lost and the phone would not boot. `mkbootimg` takes it as-is.

Nobody has published buildable XA1 kernel sources for a modern branch, so this
tree uses the prebuilt (`TARGET_FORCE_PREBUILT_KERNEL := true`). If you build a
kernel yourself, drop `TARGET_PREBUILT_KERNEL` / `TARGET_FORCE_PREBUILT_KERNEL`
and set `TARGET_KERNEL_SOURCE` instead.

## What changed versus the old tree

The previous `android_device_sony_hinoki` was written against omni/Android 8.1.
Beyond the branch bump, these were real defects:

- **Screen resolution was wrong.** It declared `1080x1920`; the XA1 panel is
  `720x1280`. Now corrected.
- **`recovery.fstab` flags were being silently discarded.** Lines were written
  as four columns (`<dev> <mnt> <fstype> flags=…`). TWRP parses a line starting
  with `/dev/` as fstab v2, where column 4 is *mount options* and column 5 is
  the flag list — so every `display=`, `backup=` and `flashimg=` in that file
  was parsed as a mount option and thrown away. All v2 lines now use five
  columns with comma-separated flags, which is what the parser expects.
- **A phantom `FOTAKernel` partition.** The old fstab mapped `/recovery` twice,
  once to `recovery` and once to `fotakernel`. The stock ueventd by-name list
  has no `fotakernel` entry; the duplicate is gone.
- **`BOARD_BOOTIMAGE_PARTITION_SIZE` held two values** (`50135040 204800`),
  which is not valid. The real sizes are 41943040 for both `boot` and
  `recovery`, and `BOARD_RECOVERYIMAGE_PARTITION_SIZE` was missing entirely, so
  nothing checked whether the built image would even fit.
- **Dead TWRP variables.** `TW_CRYPTO_REAL_BLKDEV`, `TW_CRYPTO_FS_TYPE`,
  `TW_CRYPTO_MNT_POINT`, `TW_CRYPTO_FS_OPTIONS`, `TW_CRYPTO_USE_SYSTEM_VOLD`,
  `TW_EXCLUDE_TWRPAPP`, `TW_DEFAULT_EXTERNAL_STORAGE` and friends no longer
  exist anywhere in TWRP 12.1. Encryption is now driven entirely by the
  `encryptable=` flag on `/data`.
- **`ro.build.product=hinako`** — typo for `hinoki`.
- **The stock `init.recovery.mt6757.rc` forced the USB gadget to MTP-only** at
  `on init`, racing TWRP's own USB configuration. The fragment here keeps only
  the MediaTek charger-mode writes and lets TWRP own the gadget.

## Known limitations

- **Decryption is best-effort.** `hinoki` uses full-disk encryption with the
  footer on the dedicated `metadata` partition. TWRP 12.1 decrypts FDE through
  its `vold` fork, which talks to the device's Keymaster HAL — and this phone
  ships a Keymaster 3.0 HAL from Android 8.0. It may work; it may not. If TWRP
  hangs or loops on the password prompt, set `TW_INCLUDE_CRYPTO := false` in
  `BoardConfig.mk` and rebuild. You lose decryption and keep a working recovery.
- **SELinux is permissive** (`androidboot.selinux=permissive` in the kernel
  cmdline), matching what the LineageOS 15.1 tree for this SoC used. Recovery
  needs vendor labels this tree does not ship.
- **Untested on hardware.** The tree compiles and produces a correctly sized
  `recovery.img`, but nothing here has been flashed to a physical XA1. A clean
  build proves the board and product config are internally consistent; it says
  nothing about whether the panel lights up, the touchscreen responds, or the
  partitions mount. Take a full backup of `boot`, `recovery`, `nvram`, `nvdata`
  and `persist` before you flash anything, and be ready to restore with SP Flash
  Tool.

## Credits

Partition geometry, the SoC configuration and the prebuilt kernel come from
SonyMTKDev's `android_device_sony_mt6757-common` and `android_device_sony_hinoki`
trees. TWRP is by TeamWin.

## License

Apache License 2.0, matching AOSP.
