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
# prebuilt/kernel is the stock 4.4.83 Image.gz with the MT6757 DTB appended,
# pulled out of the XA1 stock boot image. Do not gunzip or otherwise rewrite
# it: the appended DTB sits past the end of the gzip stream and lk needs it.
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_KERNEL_ARCH := arm64

BOARD_BOOT_HEADER_VERSION := 0
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_OFFSET := 0x00008000
# Stock offset, and it must stay that way. Moving the ramdisk to 0x42100000 to
# dodge lk produced an image the bootloader refused outright:
#   "Your device has been unlocked and the boot image is not working."
#
# A known-working TWRP for this device (the unofficial XA1-series build) uses
# the stock 0x45000000 with a 13,975,399-byte ramdisk, so the address is right
# and the SIZE is the real constraint. Bracketing from the three data points:
#
#   0x45000000 + 13,975,399 -> 0x45d53f67   boots
#   0x45000000 + 24,153,991 -> 0x46708f87   "overlap with lk"
#
# so lk sits somewhere in 0x45d53f67..0x46708f87. 0x46000000 is the obvious
# round candidate, which would put the ceiling at exactly 16 MB. Keep the
# ramdisk under 13.3 MB to match the known-good image and stay clear of it.
BOARD_RAMDISK_OFFSET := 0x04f88000
BOARD_SECOND_OFFSET := 0x00000000
BOARD_TAGS_OFFSET := 0x03f88000
# No androidboot.selinux=permissive: the known-working image does not carry it.
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
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

# hinoki is a legacy A-only device: no A/B slots, no dynamic partitions,
# no system-as-root, no vendor_boot and no AVB.
#
# PRODUCT_USE_DYNAMIC_PARTITIONS is deliberately not set here. Product config
# (envsetup.mk:312) runs before board config (envsetup.mk:323), so every
# PRODUCT_* variable is already .KATI_READONLY by the time this file is read
# and assigning one is a hard error. It defaults to false, which is what we
# want; device.mk is the place to set it if that ever changes.
AB_OTA_UPDATER := false
BOARD_USES_RECOVERY_AS_BOOT := false
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
# lk refuses to boot the flashed recovery image. The ramdisk was 24,153,991
# bytes, which is far larger than anything this 2017 bootloader was built to
# relocate, so it is the leading suspect. Measured from the unpacked ramdisk,
# the three settings below account for roughly 15 MB uncompressed:
#
#   TW_INCLUDE_CRYPTO   keystore2 1.6 MB, libicui18n+libicuuc 4.5 MB,
#                       gatekeeper/weaver/authsecret HALs      ~8-10 MB
#   TW_EXTRA_LANGUAGES  DroidSansFallback.ttf 3.7 MB,
#                       twres/languages 1.1 MB                  ~4.8 MB
#   TW_INCLUDE_NTFS_3G  ntfs-3g binaries                        ~1 MB
#
# Encryption is the right thing to drop first: hinoki uses FDE with the footer
# on the "metadata" partition, and TWRP 12.1 decrypts that through its vold
# fork talking to this phone's Android 8.0 Keymaster 3.0 HAL, which was always
# unlikely to work. Set this back to true (and re-check the ramdisk size) if a
# smaller image turns out not to be what lk was objecting to.
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
