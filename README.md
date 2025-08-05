# 🔥 Kali USB Creator

A streamlined Bash toolkit for building dual-partitioned, bootable **Kali Linux USB drives** with optional persistence.

## ✨ Features

- 🔧 Interactive USB device selection
- 📁 Kali ISO file chooser
- 💽 Automated USB partitioning and formatting
- 🚀 ISO flashing via `dd`
- 💾 Optional persistence partition setup
- 🧠 Echo-driven UX with logging support

## 🧰 Prerequisites

- A Linux system (tested on Ubuntu, Kali)
- Root privileges
- Core dependencies:
  - `dd`
  - `parted`
  - `mkfs.vfat`
  - `mkfs.ext4`
  - `lsblk`
  - `awk`

## 📦 Installation

```bash
git clone https://github.com/YOUR_USERNAME/Kali-USB-Creator.git
cd Kali-USB-Creator
chmod +x kali-usb-creator.sh