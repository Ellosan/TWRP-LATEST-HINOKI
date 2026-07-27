#
# Copyright (C) 2024 The Android Open Source Project
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

LOCAL_PATH := device/sony/hinoki

PRODUCT_CHARACTERISTICS := default

# hinoki has no A/B slots, so there is no update_engine / bootctrl HAL to pull
# in and nothing to slot-select at flash time.
AB_OTA_UPDATER := false

# Everything under recovery/root/ is copied verbatim into the recovery ramdisk
# by the build system (build/core/Makefile picks up $(TARGET_DEVICE_DIR)/recovery/root),
# so the MT6757 init and ueventd fragments need no rules here.

# Keep the ramdisk in the recovery image rather than in a separate vendor_boot.
PRODUCT_BUILD_VENDOR_BOOT_IMAGE := false
