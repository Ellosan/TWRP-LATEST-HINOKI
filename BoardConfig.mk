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
# NOT the stock 0x04f88000. That puts the ramdisk at 0x45000000, which is fine
# for the few-MB stock recovery ramdisk but not for TWRP's ~23 MB one: it then
# runs up to ~0x46700000 and lk rejects the boot with
#   FAILED (remote: 'invalid ramdisk address: overlap with lk')
# so lk itself lives above 0x45000000.
#
# Load it into the gap below the tags region instead. The kernel's arm64 header
# reports image_size = 29,151,232 (text+data+BSS), so the kernel really occupies
#   0x40080000 .. 0x41c4d000
# leaving 0x41c4d000 .. 0x44000000 (35.7 MB) free before the DTB at tags.
# 0x42100000 gives 4 MB of margin above the kernel and lands the 23 MB ramdisk
# at 0x42100000..0x43809000, clearing tags by 8 MB.
#
# Constraint for anyone growing the ramdisk: it must still end below
# BOARD_TAGS_OFFSET (0x44000000), i.e. stay under ~31 MB at this offset.
BOARD_RAMDISK_OFFSET := 0x02088000
BOARD_SECOND_OFFSET := 0x00e88000
BOARD_TAGS_OFFSET := 0x03f88000
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 androidboot.selinux=permissive
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

# Filesystems (exFAT and NTFS for the external SD / OTG)
TW_INCLUDE_NTFS_3G := true

# Encryption. hinoki ships full-disk encryption with the crypto footer on the
# dedicated "metadata" partition; the location is declared by the encryptable=
# flag in recovery.fstab and decryption is handled by TWRP's vold fork.
# If TWRP hangs on the password prompt on your firmware, set this to false and
# rebuild -- you lose decryption but keep a working recovery.
TW_INCLUDE_CRYPTO := true

# Extras
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_EXTRA_LANGUAGES := true
TW_DEFAULT_LANGUAGE := en
TW_CUSTOM_CPU_TEMP_PATH := /sys/devices/virtual/thermal/thermal_zone1/temp
TW_NO_BATT_PERCENT := false
TW_EXCLUDE_APEX := true

# Debug
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true

include vendor/twrp/config/BoardConfigTWRP.mk
