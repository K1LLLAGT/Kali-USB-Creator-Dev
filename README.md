🧪 Kali USB Creator Dev

An interactive Bash utility for safely creating Kali Linux bootable USBs — featuring symbolic tagging, mock-mode simulation, retry logic, safety checks, and dry-run support.

---

📦 Features

- Interactive terminal menu with symbolic logging
- Mock mode with virtual operations (usb.img, persistence.img)
- Dry-run support for step verification
- Robust error trapping and fallback flow
- Auto-backup of existing mock images
- Script dependency verification
- Per-step retry prompts and symbolic tagging logs

---

📁 Directory Structure

kali-usb-creator-dev/
├── kali-usb-creator.sh
├── config/
│   └── kali-usb.conf        # Custom settings
├── scripts/
│   ├── mock_partition.sh
│   ├── mockflashiso.sh
│   ├── mock_persistence.sh
│   ├── partition_usb.sh     # [optional] production version
│   ├── flash_iso.sh         # [optional]
│   └── setup_persistence.sh # [optional]
├── logs/
│   └── session_*.log        Live logs
│   └── summary_*.txt        # Extracted symbolic summaries


---

🚀 Quick Start

`bash
chmod +x kali-usb-creator.sh
./kali-usb-creator.sh
`

To run with specific flags:

`bash
./kali-usb-creator.sh --mode prod --auto-persist --no-color --logfile custom.log
`

---

🧠 Flags and Options

| Flag             | Description                                  |
|------------------|----------------------------------------------|
| --mode prod     | Use real device scripts                     |
| --auto-persist  | Skip persistence confirmation               |
| --no-color      | Disable terminal colors                     |
| --logfile <file>| Use custom log file path                    |
| DRY_RUN=true    | (Env var) Simulate commands without execution |

You can export flags before execution:

`bash
DEBUG_MODE=true
DRY_RUN=true
AUTO_PERSIST=true
./kali-usb-creator.sh
`

---

🔐 Safety Logic

- Backs up existing usb.img to usbbackup<timestamp>.img in mock mode
- Fails gracefully if required tools (dd, mkfs.ext4, truncate) are missing
- Interactive retry support after errors
- Symbolic tags for every milestone/error are written to log

---

🧪 Simulation Mode

Default mode is DEBUG_MODE=true and uses:

- truncate, mkfs.ext4 to simulate partitioning
- dd to mock ISO flashing and persistence creation

Resulting files:
- usb.img: Virtual USB device
- persistence.img: Simulated persistence overlay

---

📋 Logs & Symbolic Tags

Logs are stored in logs/session_<timestamp>.log. Symbolic tags track step status:

`echo
🪙 [💾] Partition simulation complete
🪙 [📀] ISO flash simulation complete
🪙 [❌] Error on line 72: dd if=/dev/zero ...
`

Summaries are extracted to logs/summary_<timestamp>.txt.

---

❗ Requirements

Ensure these tools are available:

`bash
mkfs.ext4
truncate
dd
`

Install via:

`bash
sudo apt install coreutils e2fsprogs
`

---

💡 Extensions

- Add symbolic tagging to your custom scripts/partition_usb.sh etc.
- Swap in production scripts with --mode prod
- Visualize logs with a custom parser or symbolic dashboard

---

📞 Support

For enhancements, issues, or symbolic integrations, feel free to fork and extend.
