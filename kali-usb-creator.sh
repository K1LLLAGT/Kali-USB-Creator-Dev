#!/usr/bin/env bash

# Exit on error and setup timestamped log
set -e
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/session_$(date +'%Y%m%d-%H%M').log"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

SYMBOLIC_TAG() {
    echo "🪙 [$1] $2" >> "$LOG_FILE"
}

COLOR_ECHO() {
    echo -e "\e[1;32m$1\e[0m"
}

list_usb_devices() {
    COLOR_ECHO "🔍 Step 1: Select your USB device"
    mapfile -t devices < <(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep 'disk')
    for i in "${!devices[@]}"; do echo "$((i+1))) ${devices[$i]}"; done
    read -p "Enter the number for your USB device: " choice
    device_name=$(echo "${devices[$((choice - 1))]}" | awk '{print $1}')
    echo "/dev/${device_name}"
}

list_iso_files() {
    COLOR_ECHO "📀 Step 2: Select Kali ISO file"
    mapfile -t iso_files < <(find . -maxdepth 1 -type f -name "*.iso")
    for i in "${!iso_files[@]}"; do echo "$((i+1))) ${iso_files[$i]}"; done
    read -p "Enter the number for your Kali ISO: " choice
    echo "${iso_files[$((choice - 1))]}"
}

run_command() {
    COLOR_ECHO "⚙️ Running: $*"
    "$@" && SYMBOLIC_TAG "✅" "$* succeeded"
}

partition_usb() {
    COLOR_ECHO "🧱 Partitioning USB: $1"
    run_command parted "$1" mklabel msdos
    run_command parted "$1" mkpart primary fat32 1MiB 4096MiB
    run_command mkfs.vfat "${1}1"
    SYMBOLIC_TAG "🧱" "Partition created"
}

setup_persistence() {
    COLOR_ECHO "💾 Creating persistence partition..."
    run_command parted "$1" mkpart primary ext4 4096MiB "$2"
    run_command mkfs.ext4 "${1}2"
    mkdir -p /mnt/kali_persistence
    run_command mount "${1}2" /mnt/kali_persistence
    echo "/ union" > /mnt/kali_persistence/persistence.conf
    run_command umount /mnt/kali_persistence
    SYMBOLIC_TAG "💾" "Persistence configured"
}

flash_iso() {
    COLOR_ECHO "🔥 Flashing $1 → ${2}1..."
    run_command dd if="$1" of="${2}1" bs=4M status=progress oflag=sync
    SYMBOLIC_TAG "🔥" "ISO flashed"
}

generate_python_summary() {
    COLOR_ECHO "🧠 Python audit requested..."
    if [[ -x usb_summary.py ]]; then
        ./usb_summary.py --md >> "$LOG_DIR/summary_$(date +'%Y%m%d-%H%M').md"
        SYMBOLIC_TAG "📊" "Markdown summary generated"
    fi
}

main() {
    [[ $EUID -ne 0 ]] && echo "Run as root." && exit 1

    COLOR_ECHO "🚀 Starting Kali USB Creator"
    usb_device=$(list_usb_devices)
    iso_file=$(list_iso_files)

    read -p "Enable persistent storage? [y/N]: " enable_persistence
    partition_usb "$usb_device"
    flash_iso "$iso_file" "$usb_device"

    if [[ "$enable_persistence" =~ ^[Yy]$ ]]; then
        read -p "Size for persistence partition (e.g. 6G): " size
        setup_persistence "$usb_device" "$size"
    fi

    read -p "Generate summary report? [y/N]: " audit
    [[ "$audit" =~ ^[Yy]$ ]] && generate_python_summary

    COLOR_ECHO "\n✅ All done. Bootable USB created."
    SYMBOLIC_TAG "🎉" "USB creation complete"
}

main "$@"