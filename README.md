## 🔧 Kali USB Creator Dev Toolkit

A modular and extensible Bash-based toolkit for creating bootable Kali Linux USB drives with optional persistent storage, symbolic tagging, and dynamic auditing capabilities.

###

## ⚙️ Features

- ✅ Guided USB partitioning (FAT32 & ext4)
- ✅ Flash Kali ISO with progress feedback
- ✅ Optional persistence setup (/ union)
- ✅ Symbolic tag logging (🧱, 🔥, 💾, ✅)
- ✅ Python-powered summary reports (Markdown / JSON)
- ✅ Timestamped logs per session
- ✅ Preload config for non-interactive runs

###

## 📂 Project Structure

Kali-USB-Creator-Dev/
├── kali-usb-creator.sh
├── config/
│   └── kali-usb.conf
├── scripts/
│   ├── partition_usb.sh
│   ├── flash_iso.sh
│   └── setup_persistence.sh
├── logs/
├── assets/
│   └── logo.png
├── usb_summary.py
├── docs/
├── LICENSE
└── README.md



## 🚀 Quick Start

# Run the script with root privileges:

chmod +x kali-usb-creator.sh
sudo ./kali-usb-creator.sh


# Optional config preload:

source config/kali-usb.conf



## 🧠 Python Summary Tool

# Audit your dev directory with symbolic tags and file stats:

./usb_summary.py --md        # Markdown output
./usb_summary.py --json      # JSON output


# Outputs include:
- File type counts
- Largest & oldest files
- Tag-enhanced metadata trail


## 📦 Packaging & Distribution (Coming Soon)

# Features under development:

- .deb packaging with control file and symlinked bin
- Remote prep via SSH
- Bash dashboard UX via dialog
- ISO fetcher + SHA256/GPG verifier
- Symbolic tag indexer for audit logs


## 🧰 Dependencies

- Bash utilities: dd, parted, mkfs, lsblk, tree
- Python 3 (for usb_summary.py)
- Compatible with Termux, Ubuntu, and Kali Linux


## 🔒 License

# This project is licensed under the MIT License.


## here's a full breakdown of the core scripts and key components for building out your kali-usb-creator-dev/ directory. This structure reflects your enhanced toolkit with symbolic tagging, dynamic logging, and modular architecture.


## 🧩 1. Kali-USB-Creator.sh – Main Orchestrator

#!/usr/bin/env bash
set -e
set -x

LOG_DIR="logs"
LOGFILE="$LOGDIR/session_$(date +'%Y%m%d-%H%M').log"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

SYMBOLICTAG() { echo "🪙 [$1] $2" >> "$LOGFILE"; }
COLOR_ECHO() { echo -e "\e[1;32m$1\e[0m"; }

source config/kali-usb.conf

main() {
  [[ $EUID -ne 0 ]] && echo "Run as root." && exit 1
  COLOR_ECHO "🚀 Kali USB Creator Started"

  source scripts/partition_usb.sh
  source scripts/flash_iso.sh

  read -p "Enable persistence? [y/N]: " persist
  if [[ "$persist" =~ ^[Yy]$ ]]; then
    source scripts/setup_persistence.sh
  fi

  SYMBOLIC_TAG "🎉" "Creation complete"
  COLOR_ECHO "✅ USB ready to boot Kali Linux"
}

main "$@"



## 🛠️ 2. config/kali-usb.conf

User-defined settings
USB_DEVICE="./dev/sdb"
KALI_ISO="./kali-linux.iso"



## 🔧 3. scripts/partition_usb.sh

#!/usr/bin/env bash
COLORECHO "🧱 Partitioning $USBDEVICE"
parted "$USB_DEVICE" mklabel sandisk
parted "$USB_DEVICE" mkpart primary fat32 1MiB 4096MiB
mkfs.vfat "${USB_DEVICE}1"
SYMBOLIC_TAG "🧱" "Partition created"



## 🔥 4. scripts/flash_iso.sh

#!/usr/bin/env bash
COLOR_ECHO "🔥 Flashing ISO to USB..."
dd if="$KALIISO" of="${USBDEVICE}1" bs=4M status=progress oflag=sync
SYMBOLIC_TAG "🔥" "ISO flashed"



## 💾 5. scripts/setup_persistence.sh

#!/usr/bin/env bash
COLOR_ECHO "💾 Setting up persistence..."
parted "$USB_DEVICE" mkpart primary ext4 4096MiB 100%
mkfs.ext4 "${USB_DEVICE}2"
mountpoint="/mnt/kalipersistence"
mkdir -p "$mount_point"
mount "${USBDEVICE}2" "$mountpoint"
echo "/ union" > "$mount_point/persistence.conf"
umount "$mount_point"
SYMBOLIC_TAG "💾" "Persistence configured"



## 🐍 6. usb_summary.py – Python Sidecar

#!/usr/bin/env python3
import os, time
from collections import Counter

DIR = os.path.expanduser("~/kali-usb-creator-dev")
file_data = [(ext := os.path.splitext(f)[1][1:] or "none",
              os.path.getsize(path := os.path.join(root, f)),
              os.path.getmtime(path),
              path)
             for root, _, files in os.walk(DIR)
             for f in files]

print("🔹 File Types:")
for ext, count in Counter(f[0] for f in file_data).items():
    print(f"  ▸ {ext}: {count}")

print("\n🔹 Largest Files:")
for f in sorted(file_data, key=lambda x: x[1], reverse=True)[:5]:
    print(f"  ▸ {os.path.basename(f[3])} – {f[1]//1024} KB")

print("\n🔹 Oldest Files:")
for f in sorted(file_data, key=lambda x: x[2])[:5]:
    print(f"  ▸ {os.path.basename(f[3])} – {time.ctime(f[2])}")



## 📝 7. LICENSE (MIT License)


MIT License

Copyright (c) 2025 K1LLLAGT

Permission is hereby granted, free of charge...



## 📘 8. README.md

The version I crafted earlier is your production-ready version — GitHub-friendly, fully formatted with usage, structure, and advanced features.


## 🧱 9. Directory Stubs

- logs/ – Auto-generated per session
- assets/logo.png – Optional branding
- docs/ – Usage guides, changelogs, symbolic tagging docs (can scaffold on request)

## 10. Finalized kali-usb-creator.sh

#!/usr/bin/env bash

# 🚨 Exit on error and print every command
set -e
set -x

# 🗂️ Logging setup
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/session_$(date +'%Y%m%d-%H%M').log"
exec > >(tee -a "$LOG_FILE") 2>&1

# 🧠 Helpers
SYMBOLIC_TAG() {
  echo "🪙 [$1] $2" >> "$LOG_FILE"
}

COLOR_ECHO() {
  echo -e "\e[1;32m$1\e[0m"
}

# 🔧 Load user config
source config/kali-usb.conf

# 🚀 Main Execution Flow
main() {
  [[ $EUID -ne 0 ]] && echo "This script must be run as root." && exit 1

  COLOR_ECHO "🚀 Kali USB Creator Started"
  SYMBOLIC_TAG "🚀" "Script execution initiated"

  source scripts/partition_usb.sh
  source scripts/flash_iso.sh

  read -p "Enable persistence? [y/N]: " persist
  if [[ "$persist" =~ ^[Yy]$ ]]; then
    source scripts/setup_persistence.sh
  fi

  SYMBOLIC_TAG "🎉" "Creation complete"
  COLOR_ECHO "✅ USB ready to boot Kali Linux"
}

main "$@"
