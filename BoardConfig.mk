#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 The TeamWin Recovery Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

DEVICE_PATH := device/sony/hinoki

# Platform
TARGET_BOARD_PLATFORM := mt6757
TARGET_BOARD_PLATFORM_GPU := mali-t880mp2

# Bootloader
TARGET_NO_BOOTLOADER := true
TARGET_BOOTLOADER_BOARD_NAME := mt6757

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a53
TARGET_CPU_VARIANT_RUNTIME := cortex-a53

TARGET_2ND_ARCH := arm
# Must be armv8-a, not the armv7-a-neon that Android 8-era trees used:
# combo/TARGET_linux-arm.mk lists cortex-a53 in KNOWN_ARMv8_CORES and then
# hard-errors on any 2nd arch variant other than armv8-a.
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a53

TARGET_USES_64_BIT_BINDER := true

# Kernel
#
# prebuilt/kernel is the kernel from the LineageOS 17.1 boot image for this
# device (4.4.83-AvengedKernel+), NOT the Sony stock 8.0 one. Recovery has to
# run the same kernel the ROM boots or the bootloader refuses the image with
# "the boot image is not working" -- that mismatch, not ramdisk size or load
# address, is what blocked every earlier attempt.
#
# Format is Image.gz with the MT6757 DTB appended past the end of the gzip
# stream (9,713,159 B gzip + 127,207 B DTB). Do not gunzip or rewrite it or
# the DTB is lost.
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_KERNEL_ARCH := arm64

BOARD_BOOT_HEADER_VERSION := 0
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_OFFSET := 0x00008000
# Every offset below is copied verbatim from the LineageOS 17.1 boot image, so
# the recovery lands in memory exactly where the ROM's own kernel expects to.
BOARD_RAMDISK_OFFSET := 0x04f88000
BOARD_SECOND_OFFSET := 0x00e88000
BOARD_TAGS_OFFSET := 0x03f88000
# The LineageOS boot image's cmdline is
#   bootopt=64S3,32N2,64N2 androidboot.selinux=permissive audit=0 \
#   skip_initramfs root=/dev/mmcblk0p39 rootwait ro init=/init
# Keep the first half, drop the second. skip_initramfs is what tells the kernel
# to ignore the ramdisk and mount /system as root -- correct for booting the
# ROM, fatal for a recovery, whose entire payload IS the ramdisk.
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 androidboot.selinux=permissive audit=0
BOARD_MKBOOTIMG_ARGS := \
    --board 1465391499 \
    --kernel_offset $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
    --second_offset $(BOARD_SECOND_OFFSET) \
    --tags_offset $(BOARD_TAGS_OFFSET)

# Partitions
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_BOOTIMAGE_PARTITION_SIZE := 41943040
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 41943040
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_SIZE := 209715200
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 5788139520
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_PARTITION_SIZE := 24536678400

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true
TARGET_COPY_OUT_VENDOR := vendor

# hinoki is A-only: no A/B slots, no dynamic partitions, no vendor_boot, no AVB.
# It IS system-as-root under LineageOS 17.1 -- see BOARD_BUILD_SYSTEM_ROOT_IMAGE.
#
# PRODUCT_USE_DYNAMIC_PARTITIONS is deliberately not set here. Product config
# (envsetup.mk:312) runs before board config (envsetup.mk:323), so every
# PRODUCT_* variable is already .KATI_READONLY by the time this file is read
# and assigning one is a hard error. It defaults to false, which is what we
# want; device.mk is the place to set it if that ever changes.
AB_OTA_UPDATER := false
BOARD_USES_RECOVERY_AS_BOOT := false
# LineageOS 17.1 is system-as-root: its boot image carries no ramdisk at all
# and boots with skip_initramfs root=/dev/mmcblk0p39. TWRP therefore mounts
# the system partition at /system_root and binds /system underneath it.
BOARD_BUILD_SYSTEM_ROOT_IMAGE := true
BOARD_AVB_ENABLE := false

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "BGRA_8888"

# System properties
TARGET_SYSTEM_PROP := $(DEVICE_PATH)/system.prop

# Assert
TARGET_OTA_ASSERT_DEVICE := hinoki,G3121,G3123,G3125,G3112,G3116

#
# TWRP
#
TW_DEVICE_VERSION := 1

# Display: XA1 is a 5" 720x1280 HD panel driven over fbdev.
TW_THEME := portrait_hdpi
DEVICE_RESOLUTION := 720x1280
TW_NO_SCREEN_BLANK := true
TW_SCREEN_BLANK_ON_BOOT := false

# Backlight
TW_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 128

# Storage
RECOVERY_SDCARD_ON_DATA := true
TW_INTERNAL_STORAGE_PATH := "/data/media"
TW_INTERNAL_STORAGE_MOUNT_POINT := "data"
TW_EXTERNAL_STORAGE_PATH := "/external_sd"
TW_EXTERNAL_STORAGE_MOUNT_POINT := "external_sd"
TW_NO_USB_STORAGE := false
TARGET_USE_CUSTOM_LUN_FILE_PATH := /sys/devices/platform/mt_usb/musb-hdrc.0.auto/gadget/lun%d/file

# Filesystems. exFAT is on by default (TW_NO_EXFAT would disable it).
# NTFS-3G is off to keep the ramdisk small -- see the size note below.
TW_INCLUDE_NTFS_3G := false

# Ramdisk size
#
# The images the bootloader rejected did so because of the KERNEL mismatch, not
# their size -- see the kernel note at the top. But a size ceiling at the stock
# 0x45000000 load address does independently exist: lk itself computed an
# overlap for a 24,153,991-byte ramdisk there
#   FAILED (remote: 'invalid ramdisk address: overlap with lk')
# while a known-working 13,975,399-byte one is fine. So lk sits somewhere in
# 0x45d53f67..0x46708f87 and the ceiling is real but unmeasured.
#
# These stay off for now to keep the ramdisk well under that window while the
# kernel swap is tested on its own. Once the image is confirmed to boot, turn
# them back on one at a time -- that also measures where the ceiling actually
# is, which is worth knowing.
TW_INCLUDE_CRYPTO := false

# Extras
#
# repacktools (magiskboot ~1.2 MB + magiskpolicy), resetprop and MTP are all
# off purely for ramdisk size -- the ramdisk has to fit under lk at the stock
# load address. Turn them back on once the image is known to boot and the size
# ceiling is actually measured rather than inferred.
TW_INCLUDE_REPACKTOOLS := false
TW_INCLUDE_RESETPROP := false
TW_INCLUDE_LIBRESETPROP := false
TW_EXCLUDE_MTP := true
TW_EXTRA_LANGUAGES := false
TW_DEFAULT_LANGUAGE := en
TW_CUSTOM_CPU_TEMP_PATH := /sys/devices/virtual/thermal/thermal_zone1/temp
TW_NO_BATT_PERCENT := false
TW_EXCLUDE_APEX := true

# Debug. Off for size; logd/logcat is worth ~1 MB and we cannot afford it until
# the image boots. Re-enable when debugging a booting-but-broken TWRP.
TWRP_INCLUDE_LOGCAT := false
TARGET_USES_LOGD := false

include vendor/twrp/config/BoardConfigTWRP.mk
