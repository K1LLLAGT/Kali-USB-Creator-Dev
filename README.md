# 🧪 Kali USB Creator (dev)

An interactive Bash utility for safely creating Kali Linux bootable USBs — with
symbolic milestone tagging, a mock-mode simulation, dry-run support, retry
prompts, dependency checks, and hard safety gates before any real write.

> **Default mode is `mock`.** Nothing touches a real device until you pass
> `--mode prod` *and* clear the typed device confirmation.

---

## 📁 Layout

```
kali-usb-creator-dev/
├── kali-usb-creator.sh          # interactive orchestrator (menu + flags)
├── config/
│   └── kali-usb.conf            # defaults (overridden by env vars and flags)
├── scripts/
│   ├── lib_common.sh            # shared logging / symbolic tags / safety helpers
│   ├── mock_partition.sh        # mock: create + format usb.img (with backup)
│   ├── mockflashiso.sh          # mock: simulate ISO flash into usb.img
│   ├── mock_persistence.sh      # mock: create + format persistence.img
│   ├── flash_iso.sh             # prod: dd isohybrid ISO -> device  (DESTRUCTIVE)
│   ├── partition_usb.sh         # prod: add persistence partition
│   └── setup_persistence.sh     # prod: format + write persistence.conf
└── logs/
    ├── session_<ts>.log         # full session log
    └── summary_<ts>.txt         # extracted 🪙 milestone lines
```

`lib_common.sh` is shared by the orchestrator and every step script, so symbolic
tagging and dry-run behavior are consistent across the whole pipeline.

---

## 🚀 Quick start

```bash
chmod +x kali-usb-creator.sh scripts/*.sh
./kali-usb-creator.sh
```

With flags:

```bash
./kali-usb-creator.sh --mode prod --auto-persist --no-color --logfile custom.log
```

With environment overrides (these win over `config/kali-usb.conf`):

```bash
DRY_RUN=true AUTO_PERSIST=true ./kali-usb-creator.sh
```

---

## 🧠 Flags & options

| Flag                | Description                                   |
|---------------------|-----------------------------------------------|
| `--mode <mock\|prod>` | Run mode. Default `mock`.                   |
| `--auto-persist`    | Skip the persistence confirmation prompt.     |
| `--no-color`        | Disable terminal colors.                      |
| `--logfile <file>`  | Write the session log to a custom path.       |
| `-h`, `--help`      | Show usage.                                   |

Environment overrides: `DRY_RUN`, `DEBUG_MODE`, `AUTO_PERSIST`, `USE_COLOR`,
plus any value defined in `config/kali-usb.conf` (`MOCK_DIR`, `USB_IMG_SIZE`,
`TARGET_DEVICE`, `ISO_PATH`, etc.).

**Precedence:** CLI flags / exported env vars  ➜  override  ➜  `kali-usb.conf`.

---

## 🖥️ Menu

```
1) Run full flow
2) Partition only
3) Flash ISO only
4) Persistence only
5) Toggle dry-run
6) Toggle mode (mock/prod)
7) Show config
8) View session summary
9) Quit
```

In **mock** the flow is partition → flash → persistence.
In **prod** the flow is the real-world order flash → partition → persistence
(the ISO `dd` rewrites the partition table, so partitioning happens after).

---

## 🔐 Safety logic

- **Mock by default** — `usb.img` / `persistence.img` are plain files; no block
  device is involved.
- **Auto-backup** — an existing `usb.img` is copied to
  `usb_backup_<timestamp>.img` before being recreated.
- **Dependency checks** — refuses to start a step if `dd`, `truncate`,
  `mkfs.ext4` (mock) or `parted`, `partprobe`, `lsblk`, `findmnt` (prod) are
  missing.
- **Dry-run** — `DRY_RUN=true` prints every state-changing command instead of
  running it.
- **Prod gates** — `assert_safe_target` refuses non-block-device targets and any
  disk hosting `/`, warns if the device is not flagged removable, and
  `confirm_device` requires you to retype the exact device path before writing.
- **Retry prompts** — a failed step logs a `❌` tag and offers a retry (skipped
  automatically under `--auto-persist`).

---

## 🪙 Symbolic tags

Every milestone and error is tagged in the log and lifted into the summary:

```
🪙 [🚀] Session started (mock mode)
🪙 [🔎] Dependency check passed (mock mode)
🪙 [🗄️] Backed up existing usb.img -> usb_backup_20260602_200009.img
🪙 [💾] Partition simulation complete
🪙 [📀] ISO flash simulation complete
🪙 [🧩] Persistence simulation complete
🪙 [❌] Step failed: Flash ISO
🪙 [✅] Full flow finished (mock mode)
```

`logs/summary_<ts>.txt` is just the `🪙` lines, extracted on exit.

---

## ❗ Requirements

Mock mode:

```bash
sudo apt install coreutils e2fsprogs      # truncate, dd, mkfs.ext4
```

Prod mode additionally needs `parted` / `partprobe` / `lsblk` / `findmnt`:

```bash
sudo apt install parted util-linux
```

---

## 💡 Extending

- Drop your own logic into the `prod` scripts — they already `source
  lib_common.sh`, so `symlog`, `run_cmd`, and the safety helpers are available.
- Each step script is independently runnable; the orchestrator just exports the
  config as environment variables and calls them, so you can test one in
  isolation:

  ```bash
  LIB_DIR=scripts MODE=mock USB_IMG=./mock/usb.img USB_IMG_SIZE=2G \
    MOCK_DIR=./mock DRY_RUN=true bash scripts/mock_partition.sh
  ```
