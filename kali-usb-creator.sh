#!/usr/bin/env bash

# 🧩 Initialize Environment
mkdir -p logs scripts
TIMESTAMP="$(date +'%Y%m%d-%H%M')"
LOG_FILE="logs/session_${TIMESTAMP}.log"

# 🧠 Default Flags
DEBUG_MODE=true
AUTO_PERSIST=false
NO_COLOR=false
DRY_RUN=false

# 🔧 Load Configuration
source config/kali-usb.conf

# 🎨 Visual + Symbolic Helpers
COLOR_ECHO() {
  [[ "$NO_COLOR" == true ]] && echo "$1" || echo -e "\e[1;32m$1\e[0m"
}

SYMBOLIC_TAG() {
  echo "🪙 [$1] $2" >> "$LOG_FILE"
}

# 🔧 Error Trap
handle_error() {
  local lineno="$1"
  local cmd="$2"
  SYMBOLIC_TAG "❌" "Error on line $lineno: $cmd"
  COLOR_ECHO "❌ An error occurred — line $lineno: $cmd"
}

trap 'handle_error $LINENO "$BASH_COMMAND"' ERR

# 🔀 Mode + Safety Utilities
detect_script() {
  local mock="$1" prod="$2"
  [[ "$DEBUG_MODE" == true ]] && echo "$mock" || echo "$prod"
}

confirm_production_switch() {
  read -p "Switch to production scripts? This may affect devices. [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    DEBUG_MODE=false
    SYMBOLIC_TAG "⚡" "Production mode activated"
  fi
}

check_mock_image_exists() {
  if [[ "$DEBUG_MODE" == true && -f "usb.img" ]]; then
    local backup="usb_backup_${TIMESTAMP}.img"
    mv usb.img "$backup"
    SYMBOLIC_TAG "⚠️" "usb.img already existed — backed up to $backup"
    COLOR_ECHO "⚠️ usb.img already exists — backed up to $backup"
  fi
}

check_dependencies() {
  for cmd in mkfs.ext4 truncate dd; do
    if ! command -v "$cmd" > /dev/null; then
      handle_error $LINENO "$cmd not found"
      exit 1
    fi
  done
}

# 🧪 Embedded Mock Modules
cat <<'EOF' > scripts/mock_partition.sh
COLOR_ECHO "🧪 Simulating partition..."
[[ "$DRY_RUN" == true ]] || (truncate -s 2G usb.img && mkfs.ext4 usb.img > /dev/null)
SYMBOLIC_TAG "💾" "Partition simulation complete"
EOF

cat <<'EOF' > scripts/mock_flash_iso.sh
COLOR_ECHO "🧪 Simulating ISO flash..."
[[ "$DRY_RUN" == true ]] || dd if=/dev/zero of=usb.img bs=1M count=100 status=none
SYMBOLIC_TAG "📀" "ISO flash simulation complete"
EOF

cat <<'EOF' > scripts/mock_persistence.sh
COLOR_ECHO "🧪 Simulating persistence setup..."
[[ "$DRY_RUN" == true ]] || dd if=/dev/zero of=persistence.img bs=1M count=256 status=none
SYMBOLIC_TAG "🔒" "Persistence simulation complete"
EOF

# ⚙️ Resolve Scripts
PARTITION_SCRIPT="$(detect_script "scripts/mock_partition.sh" "scripts/partition_usb.sh")"
FLASH_SCRIPT="$(detect_script "scripts/mock_flash_iso.sh" "scripts/flash_iso.sh")"
PERSISTENCE_SCRIPT="$(detect_script "scripts/mock_persistence.sh" "scripts/setup_persistence.sh")"

# 🎛️ Interactive Flow
retry_step() {
  local step="$1"
  local label="$2"
  until "$step"; do
    read -p "Retry $label step? [y/N]: " retry
    [[ "$retry" =~ ^[Yy]$ ]] || break
  done
}

main_menu() {
  COLOR_ECHO "🧪 Kali USB Creator — Mode: $([[ "$DEBUG_MODE" == true ]] && echo 'Mock' || echo 'Production')"
  SYMBOLIC_TAG "🧪" "Interactive menu activated"
  check_dependencies

  PS3="🛠️ Choose an action: "
  options=(
    "🧱 Partition USB"
    "📀 Flash ISO"
    "🔒 Setup Persistence"
    "🚀 Run Full Flow"
    "⚡ Switch to Production"
    "📋 Show Log Summary"
    "❌ Exit"
  )

  select opt in "${options[@]}"; do
    case $REPLY in
      1) check_mock_image_exists; retry_step "source $PARTITION_SCRIPT" "partition" ;;
      2) retry_step "source $FLASH_SCRIPT" "flash" ;;
      3) retry_step "source $PERSISTENCE_SCRIPT" "persistence" ;;
      4)
        check_mock_image_exists
        retry_step "source $PARTITION_SCRIPT" "partition"
        retry_step "source $FLASH_SCRIPT" "flash"
        if [[ "$AUTO_PERSIST" == true ]]; then
          retry_step "source $PERSISTENCE_SCRIPT" "persistence"
        else
          read -p "Enable persistence? [y/N]: " persist
          [[ "$persist" =~ ^[Yy]$ ]] && retry_step "source $PERSISTENCE_SCRIPT" "persistence"
        fi
        SYMBOLIC_TAG "🎯" "Full flow complete"
        COLOR_ECHO "✅ All tasks executed successfully"
        ;;
      5) confirm_production_switch ;;
      6)
        grep '🪙' "$LOG_FILE" | sed 's/🪙 \[\(.*\)\] \(.*\)/\1: \2/' > "logs/summary_$TIMESTAMP.txt"
        COLOR_ECHO "📋 Summary saved to logs/summary_$TIMESTAMP.txt"
        ;;
      7) break ;;
      *) COLOR_ECHO "⛔ Invalid selection" ;;
    esac
  done
}

main_menu