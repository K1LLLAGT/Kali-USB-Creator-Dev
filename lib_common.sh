#!/usr/bin/env bash
# lib_common.sh — shared helpers for kali-usb-creator
# Sourced by the main script and every step script. No top-level side effects.

# ---------------------------------------------------------------------------
# Color setup (honor USE_COLOR; default on if attached to a TTY)
# ---------------------------------------------------------------------------
_setup_colors() {
    if [[ "${USE_COLOR:-true}" == "true" ]]; then
        C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'
        C_RED=$'\033[31m';  C_GRN=$'\033[32m'; C_YLW=$'\033[33m'
        C_BLU=$'\033[34m';  C_CYN=$'\033[36m'
    else
        C_RESET=""; C_DIM=""; C_BOLD=""
        C_RED="";   C_GRN="";  C_YLW=""
        C_BLU="";   C_CYN=""
    fi
}
_setup_colors

# ---------------------------------------------------------------------------
# Logging. Everything goes to stdout and, if LOGFILE is set, appended there.
# ---------------------------------------------------------------------------
_ts() { date '+%Y-%m-%d %H:%M:%S'; }

_emit() {  # _emit <line-without-newline>
    local line="$1"
    printf '%s\n' "$line"
    if [[ -n "${LOGFILE:-}" ]]; then
        # strip ANSI before writing to file
        printf '%s\n' "$line" | sed -r 's/\x1B\[[0-9;]*[mK]//g' >> "$LOGFILE"
    fi
}

log()  { _emit "${C_DIM}[$(_ts)]${C_RESET} $*"; }
info() { _emit "${C_CYN}[*]${C_RESET} $*"; }
ok()   { _emit "${C_GRN}[+]${C_RESET} $*"; }
warn() { _emit "${C_YLW}[!]${C_RESET} $*"; }
err()  { _emit "${C_RED}[x]${C_RESET} $*"; }

# Symbolic milestone tags. These lines (marked with the coin glyph) are what the
# main script extracts into the per-session summary.
symlog() {  # symlog <emoji> <message>
    local glyph="$1"; shift
    _emit "🪙 [${glyph}] $*"
}

die() { err "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Dry-run aware command runner. Use for any state-changing command.
#   run_cmd dd if=... of=...
# Commands needing shell features (pipes/redirects) should be wrapped in a
# function and that function passed to run_cmd, or guarded inline with is_dry.
# ---------------------------------------------------------------------------
is_dry() { [[ "${DRY_RUN:-false}" == "true" ]]; }

run_cmd() {
    if is_dry; then
        log "${C_BLU}DRY_RUN${C_RESET} would run: $*"
        return 0
    fi
    log "exec: $*"
    "$@"
}

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
require_cmd() {  # require_cmd dd mkfs.ext4 truncate ...
    local missing=()
    local c
    for c in "$@"; do
        command -v "$c" >/dev/null 2>&1 || missing+=("$c")
    done
    if (( ${#missing[@]} )); then
        err "Missing required tools: ${missing[*]}"
        warn "Install with: sudo apt install coreutils e2fsprogs util-linux"
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Production safety: refuse to touch the wrong block device.
# ---------------------------------------------------------------------------
assert_safe_target() {  # assert_safe_target /dev/sdX
    local dev="$1"
    [[ -n "$dev" ]]   || die "TARGET_DEVICE is not set (required for --mode prod)."
    [[ -b "$dev" ]]   || die "$dev is not a block device."

    # Never write to the disk hosting the root filesystem.
    local rootsrc
    rootsrc="$(findmnt -no SOURCE / 2>/dev/null || true)"
    if [[ -n "$rootsrc" && "$rootsrc" == "$dev"* ]]; then
        die "Refusing: $dev appears to host the root filesystem ($rootsrc)."
    fi

    # Warn loudly if the kernel does not report the device as removable.
    local base removable
    base="$(basename "$dev")"
    base="${base%%[0-9]*}"   # strip partition number for /sys lookup
    removable="/sys/block/${base}/removable"
    if [[ -f "$removable" && "$(cat "$removable" 2>/dev/null)" != "1" ]]; then
        warn "$dev does NOT report as removable. Double-check this is your USB stick."
    fi
}

confirm_device() {  # confirm_device /dev/sdX  — typed confirmation of destructive write
    local dev="$1"
    if is_dry; then
        log "DRY_RUN: skipping destructive-write confirmation for $dev"
        return 0
    fi
    local ans
    read -r -p "$(printf '%sType the device path %q to confirm destructive write: %s' "${C_YLW}" "$dev" "${C_RESET}")" ans
    [[ "$ans" == "$dev" ]] || die "Confirmation did not match ($ans != $dev). Aborting."
}
