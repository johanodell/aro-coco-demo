#!/usr/bin/env bash
# setup-demo-prereqs.sh
# Purpose: Prepares RHEL bastion for ARO CoCo Demo (Kitty, EPEL, PV, Cowsay)

set -euo pipefail

# --- Formatting Helpers ---
log() { echo -e "\n\033[38;2;102;204;255m[*] $*\033[0m"; }
ok()  { echo -e "\033[0;32m[✓] $*\033[0m"; }
err() { echo -e "\033[0;31m[!] $*\033[0m" >&2; }
BLUE='\033[38;2;102;204;255m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RESET='\033[0m'

# Use sudo only if not running as root
SUDO=""
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  SUDO="sudo"
fi

# --- 1. OS Detection ---
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
else
  err "Cannot read /etc/os-release. OS detection failed."
  exit 1
fi

MAJOR="${VERSION_ID%%.*}"
log "Detected RHEL ${MAJOR} environment."

# --- 2. Install Kitty Terminfo ---
log "Installing Kitty Terminfo (ensures terminal renders correctly)..."
$SUDO dnf -y install curl ncurses ncurses-term >/dev/null

TMP="$(mktemp -d /tmp/kitty-ti-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
TI="${TMP}/kitty.terminfo"

curl -fsSL -o "${TI}" https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo
$SUDO tic -x -o /usr/share/terminfo "${TI}"

if infocmp xterm-kitty >/dev/null 2>&1; then
  ok "Kitty terminfo installed system-wide."
else
  err "Kitty terminfo installation failed."
fi

# --- 3. Setup EPEL Repository ---
log "Configuring EPEL repository for extra packages..."
EPEL_RPM="https://dl.fedoraproject.org/pub/epel/epel-release-latest-${MAJOR}.noarch.rpm"
$SUDO dnf install -y "$EPEL_RPM" >/dev/null
ok "EPEL repository active."

# --- 4. Install PV (Pipe Viewer) ---
log "Installing 'pv' (required for demo-magic typing effects)..."
$SUDO dnf install -y pv >/dev/null
if command -v pv >/dev/null; then
  ok "pv $(pv --version | head -n 1) installed."
else
  err "Failed to install pv."
fi

# --- 5. Install Cowsay ---
log "Installing 'cowsay'..."
$SUDO dnf install -y cowsay >/dev/null

# --- 6. Verify OpenShift Client (oc) ---
log "Checking OpenShift client version..."
if command -v oc >/dev/null; then
    OC_VER=$(oc version --client | head -n 1)
    ok "OpenShift Client found: ${OC_VER}"
else
    err "OpenShift 'oc' client not found! Please ensure it is installed."
fi

# --- FINAL VERIFICATION & REMINDER ---
log "Final verification..."
if command -v cowsay >/dev/null; then
    cowsay "Moo! All tools are installed. Ready for the CoCo Demo!"
    
    echo -e "\n${BLUE}==========================================================${RESET}"
    echo -e "${YELLOW}FINAL STEP:${RESET} You must now initialize your demo variables."
    echo -e "Run the following command in your terminal:"
    echo -e ""
    echo -e "    ${GREEN}source ../vars.sh${RESET}"
    echo -e "${BLUE}==========================================================${RESET}\n"
    
    ok "Prerequisites Setup Complete!"
else
    err "Setup verification: FAILED"
    exit 1
fi