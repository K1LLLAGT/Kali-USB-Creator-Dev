#!/usr/bin/env bash
# kali-usb-creator.sh — interactive Kali Linux bootable-USB creator
# Mock (simulated) by default; real device writes only with --mode prod.
set -euo pipefail

# ---------------------------------------------------------------------------
# Locate ourselves and load shared helpers + config
# ---------------------------------------------------------------------------
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${ROOT_DIR}/scripts"
CONFIG_FILE="${ROOT_DIR}/config/kali-usb.conf"

# Variables that a user may legitimately override via the environment. We
# snapshot whichever are already set, source the config (which provides
# defaults), then restore the snapshots so env vars win over the config file.
_OVERRIDABLE=(MODE DRY_RUN DEBUG_MODE AUTO_PERSIST USE_COLOR
              MOCK_DIR USB_IMG PERSIST_IMG USB_IMG_SIZE PERSIST_IMG_SIZE
              TARGET_DEVICE ISO_PATH PERSIST_LABEL PERSIST_SIZE_MB)
for _v in "${_OVERRIDABLE[@]}"; do
    if [[ -n "${!_v+set}" ]]; then
        printf -v "_ENV_${_v}" '%s' "${!_v}"
        eval "_HAD_${_v}=1"
    fi
done

# Load config to supply defaults.
# shellcheck source=config/kali-usb.conf
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# Restore any environment overrides that were present before sourcing.
for _v in "${_OVERRIDABLE[@]}"; do
    _had="_HAD_${_v}"
    if [[ "${!_had:-}" == "1" ]]; then
        _src="_ENV_${_v}"
        printf -v "$_v" '%s' "${!_src}"
    fi
done

# Final fallbacks if neither env nor config provided a value.
MODE="${MODE:-mock}"
DRY_RUN="${DRY_RUN:-false}"
DEBUG_MODE="${DEBUG_MODE:-true}"
AUTO_PERSIST="${AUTO_PERSIST:-false}"
USE_COLOR="${USE_COLOR:-true}"

# shellcheck source=scripts/lib_common.sh
source "${LIB_DIR}/lib_common.sh"

# ---------------------------------------------------------------------------
# CLI flags
# ---------------------------------------------------------------------------
CUSTOM_LOGFILE=""
usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

  --mode <mock|prod>   Run mode. Default: mock (safe simulation).
  --auto-persist       Skip the persistence confirmation prompt.
  --no-color           Disable terminal colors.
  --logfile <file>     Write the session log to this path.
  -h, --help           Show this help.

Environment overrides: DRY_RUN, DEBUG_MODE, AUTO_PERSIST, USE_COLOR
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)        MODE="${2:-}"; shift 2 ;;
        --auto-persist) AUTO_PERSIST="true"; shift ;;
        --no-color)    USE_COLOR="false"; shift ;;
        --logfile)     CUSTOM_LOGFILE="${2:-}"; shift 2 ;;
        -h|--help)     usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    esac
done

case "$MODE" in mock|prod) ;; *) echo "Invalid --mode: $MODE" >&2; exit 2 ;; esac

# Re-apply colors in case --no-color flipped after the lib was sourced.
_setup_colors

# ---------------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------------
mkdir -p "${ROOT_DIR}/logs"
STAMP="$(date +%Y%m%d_%H%M%S)"
if [[ -n "$CUSTOM_LOGFILE" ]]; then
    LOGFILE="$CUSTOM_LOGFILE"
else
    LOGFILE="${ROOT_DIR}/logs/session_${STAMP}.log"
fi
SUMMARY="${ROOT_DIR}/logs/summary_${STAMP}.txt"
: > "$LOGFILE"

# Export everything the step scripts read.
export LIB_DIR LOGFILE USE_COLOR DRY_RUN MODE
export MOCK_DIR USB_IMG PERSIST_IMG USB_IMG_SIZE PERSIST_IMG_SIZE
export TARGET_DEVICE ISO_PATH PERSIST_LABEL PERSIST_SIZE_MB AUTO_PERSIST

# ---------------------------------------------------------------------------
# Error trapping: log unexpected failures with line + command, then continue
# to the summary on the way out.
# ---------------------------------------------------------------------------
on_error() {
    local exit_code=$? line="$1" cmd="$2"
    symlog "❌" "Error on line ${line}: ${cmd} (exit ${exit_code})"
}
trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR
trap 'write_summary' EXIT

write_summary() {
    # Extract the symbolic milestone/error lines into the summary file.
    if [[ -f "$LOGFILE" ]]; then
        grep '🪙' "$LOGFILE" > "$SUMMARY" 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------------------
# Step dispatch (mock vs prod) + retry wrapper
# ---------------------------------------------------------------------------
script_for() {  # script_for <partition|flash|persist>
    case "$1:$MODE" in
        partition:mock) echo "${LIB_DIR}/mock_partition.sh" ;;
        flash:mock)     echo "${LIB_DIR}/mockflashiso.sh" ;;
        persist:mock)   echo "${LIB_DIR}/mock_persistence.sh" ;;
        partition:prod) echo "${LIB_DIR}/partition_usb.sh" ;;
        flash:prod)     echo "${LIB_DIR}/flash_iso.sh" ;;
        persist:prod)   echo "${LIB_DIR}/setup_persistence.sh" ;;
        *) return 1 ;;
    esac
}

run_step() {  # run_step <key> <human name>
    local key="$1" name="$2" script
    script="$(script_for "$key")" || { err "No script for step '$key'"; return 1; }
    if [[ ! -x "$script" && ! -f "$script" ]]; then
        err "Step script missing: $script"
        return 1
    fi
    info "Step: ${name}  [${MODE}]"
    # Run in an 'if' so errexit/ERR are suppressed for the controlled attempt.
    if bash "$script"; then
        return 0
    fi
    return 1
}

with_retry() {  # with_retry <key> <human name>
    local key="$1" name="$2"
    while true; do
        if run_step "$key" "$name"; then
            return 0
        fi
        symlog "❌" "Step failed: ${name}"
        if [[ "$AUTO_PERSIST" == "true" ]]; then
            warn "Auto mode: not retrying '${name}'."
            return 1
        fi
        local ans
        read -r -p "$(printf '%sRetry %q? [y/N] %s' "${C_YLW}" "$name" "${C_RESET}")" ans
        case "${ans,,}" in
            y|yes) info "Retrying ${name}..." ;;
            *)     warn "Skipping ${name}."; return 1 ;;
        esac
    done
}

confirm_persistence() {
    [[ "$AUTO_PERSIST" == "true" ]] && return 0
    local ans
    read -r -p "$(printf '%sAdd a persistence overlay? [y/N] %s' "${C_CYN}" "${C_RESET}")" ans
    [[ "${ans,,}" =~ ^(y|yes)$ ]]
}

# ---------------------------------------------------------------------------
# Flows
# ---------------------------------------------------------------------------
preflight() {
    info "Verifying dependencies..."
    if [[ "$MODE" == "mock" ]]; then
        require_cmd dd truncate mkfs.ext4 || die "Install missing tools and re-run."
    else
        require_cmd dd parted mkfs.ext4 lsblk findmnt sync partprobe \
            || die "Install missing tools and re-run."
    fi
    symlog "🔎" "Dependency check passed (${MODE} mode)"
}

run_full() {
    preflight
    if [[ "$MODE" == "prod" ]]; then
        # Correct real-world order: flash whole device, then carve persistence.
        with_retry flash     "Flash ISO"          || return 1
        with_retry partition "Create persistence partition" || return 1
        if confirm_persistence; then
            with_retry persist "Set up persistence" || return 1
        else
            symlog "⏭️" "Persistence skipped by user"
        fi
    else
        with_retry partition "Partition (simulated)" || return 1
        with_retry flash     "Flash ISO (simulated)" || return 1
        if confirm_persistence; then
            with_retry persist "Persistence (simulated)" || return 1
        else
            symlog "⏭️" "Persistence skipped by user"
        fi
    fi
    symlog "✅" "Full flow finished (${MODE} mode)"
    ok "All requested steps complete."
}

show_config() {
    cat <<EOF
${C_BOLD}Current configuration${C_RESET}
  mode          : ${MODE}
  dry-run       : ${DRY_RUN}
  auto-persist  : ${AUTO_PERSIST}
  color         : ${USE_COLOR}
  logfile       : ${LOGFILE}
  summary       : ${SUMMARY}
  --- mock ---
  mock dir      : ${MOCK_DIR}
  usb.img       : ${USB_IMG} (${USB_IMG_SIZE})
  persistence   : ${PERSIST_IMG} (${PERSIST_IMG_SIZE})
  --- prod ---
  target device : ${TARGET_DEVICE:-<unset>}
  iso path      : ${ISO_PATH:-<unset>}
  persist label : ${PERSIST_LABEL}
  persist size  : ${PERSIST_SIZE_MB} MB
EOF
}

view_summary() {
    write_summary
    if [[ -s "$SUMMARY" ]]; then
        echo "${C_BOLD}Session summary (${SUMMARY}):${C_RESET}"
        cat "$SUMMARY"
    else
        warn "No symbolic milestones recorded yet."
    fi
}

# ---------------------------------------------------------------------------
# Interactive menu
# ---------------------------------------------------------------------------
banner() {
    echo "${C_GRN}${C_BOLD}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║        🧪  Kali USB Creator  (dev)         ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo "${C_RESET}${C_DIM}  mode=${MODE}  dry_run=${DRY_RUN}  auto_persist=${AUTO_PERSIST}${C_RESET}"
}

menu() {
    while true; do
        echo
        banner
        cat <<EOF

  1) Run full flow
  2) Partition only
  3) Flash ISO only
  4) Persistence only
  5) Toggle dry-run        (now: ${DRY_RUN})
  6) Toggle mode           (now: ${MODE})
  7) Show config
  8) View session summary
  9) Quit
EOF
        local choice
        read -r -p "  > " choice
        case "$choice" in
            1) run_full || warn "Flow ended early." ;;
            2) preflight; with_retry partition "Partition" || true ;;
            3) preflight; with_retry flash     "Flash ISO" || true ;;
            4) preflight; with_retry persist   "Persistence" || true ;;
            5) [[ "$DRY_RUN" == "true" ]] && DRY_RUN=false || DRY_RUN=true
               export DRY_RUN; info "dry-run is now ${DRY_RUN}" ;;
            6) [[ "$MODE" == "mock" ]] && MODE=prod || MODE=mock
               export MODE; info "mode is now ${MODE}"
               [[ "$MODE" == "prod" ]] && warn "PROD mode writes to real devices." ;;
            7) show_config ;;
            8) view_summary ;;
            9|q|Q) info "Bye."; break ;;
            *) warn "Unknown choice: $choice" ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Entry
# ---------------------------------------------------------------------------
log "Session start — mode=${MODE} dry_run=${DRY_RUN} log=${LOGFILE}"
symlog "🚀" "Session started (${MODE} mode)"
[[ "$MODE" == "prod" ]] && warn "PROD mode active — operations write to real devices."
menu
