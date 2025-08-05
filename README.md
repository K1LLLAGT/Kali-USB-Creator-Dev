🔧 Kali USB Creator Dev Toolkit

A modular and extensible toolkit for creating bootable Kali Linux USB drives with optional persistent storage, symbolic tagging, and dynamic auditing capabilities.

⚙️ Features

- ✅ Guided USB partitioning (FAT32 & ext4)
- ✅ Flash Kali ISO with progress feedback
- ✅ Optional persistence setup (/ union)
- ✅ Symbolic tag logging (🧱, 🔥, 💾, ✅)
- ✅ Python-powered summary reports (Markdown / JSON)
- ✅ Timestamped logs per session
- ✅ Preload config for non-interactive runs

📂 Project Structure

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

🚀 Quick Start

Run the script with root access:

chmod +x kali-usb-creator.sh
sudo ./kali-usb-creator.sh

Optional config preload:

source config/kali-usb.conf

🧠 Python Summary Tool

Audit your dev directory with symbolic tags and file stats:

./usb_summary.py --md        # Markdown output
./usb_summary.py --json      # JSON output

Outputs include:
- File type counts
- Largest & oldest files
- Tag-enhanced metadata trail

📦 Packaging & Distribution (Coming Soon)

We're working on:
- .deb packaging structure (control, postinst hooks, symlinked bin)
- Remote prep via SSH
- Bash dashboard UX via dialog
- ISO fetcher + SHA256/GPG verifier

🧰 Dependencies

- Bash utilities: dd, parted, mkfs, lsblk, tree
- Python 3 (for auditing module)
- Compatible with Termux, Ubuntu, Kali Linux

🔒 License

This project is licensed under the MIT License.

