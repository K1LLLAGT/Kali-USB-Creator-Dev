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

`text
kali-usb-creator-dev/
├── kali-usb-creator.sh          # Main orchestrator script
├── config/
│   └── kali-usb.conf            # Device + ISO config
├── scripts/
│   ├── partition_usb.sh
│   ├── flash_iso.sh
│   └── setup_persistence.sh
├── logs/                        # Timestamped symbolic logs
├── assets/
│   └── logo.png                 # Branding graphic
├── usb_summary.py               # Python CLI sidecar auditor
├── docs/                        # Usage guides and changelogs
├── LICENSE                      # MIT license
└── README.md                    # This file
`

###

## 🚀 Quick Start

Run the script with root privileges:

`bash
chmod +x kali-usb-creator.sh
sudo ./kali-usb-creator.sh
`

Optional config preload:

`bash
source config/kali-usb.conf
`

###

## 🧠 Python Summary Tool

Audit your dev directory with symbolic tags and file stats:

`bash
./usb_summary.py --md        # Markdown output
./usb_summary.py --json      # JSON output
`

Outputs include:
- File type counts
- Largest & oldest files
- Tag-enhanced metadata trail

###

## 📦 Packaging & Distribution (Coming Soon)

Features under development:

- .deb packaging with control file and symlinked bin
- Remote prep via SSH
- Bash dashboard UX via dialog
- ISO fetcher + SHA256/GPG verifier
- Symbolic tag indexer for audit logs

###

## 🧰 Dependencies

- Bash utilities: dd, parted, mkfs, lsblk, tree
- Python 3 (for usb_summary.py)
- Compatible with Termux, Ubuntu, and Kali Linux

###

## 🔒 License

This project is licensed under the MIT License.

###

> Made for makers. Symbolically tagged. Proudly persistent. 👨‍💻
`
