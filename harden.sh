#!/bin/bash

# ==========================================
# PROJECT: Linux Hardening Script
# AUTHOR: Chinmay
# DATE: $(date)
# ==========================================

echo "🚀 Initializing Hardening Script..."

# --- CONFIGURATION ---
# Colors for professional output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper function for status updates
log_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

log_error() {
    echo -e "${RED}[-] $1${NC}"
}

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (sudo ./harden.sh)"
    exit 1
fi
log_success "Root privileges confirmed."

# 2. SYSTEM UPDATE & UPGRADE
echo "---------------------------------"
echo "🔄 Starting System Update..."

# Update package list (suppress output for cleanliness)
apt update -y > /dev/null 2>&1

if [ $? -eq 0 ]; then
    log_success "Package list updated."
else
    log_error "Failed to update package list."
    exit 1
fi

# Upgrade installed packages
# DEBIAN_FRONTEND=noninteractive prevents pop-ups asking for input
DEBIAN_FRONTEND=noninteractive apt upgrade -y > /dev/null 2>&1
log_success "System packages upgraded."

# 3. SYSTEM CLEANUP
echo "🧹 Removing unused packages..."

# Autoremove deletes dependencies that are no longer needed
apt autoremove -y > /dev/null 2>&1
apt autoclean -y > /dev/null 2>&1

log_success "System cleanup complete."

# 4. FIREWALL SETUP (UFW)
echo "---------------------------------"
echo "🛡️ Configuring Firewall..."

# Check if UFW is installed; if not, install it.
if ! command -v ufw &> /dev/null; then
    echo "Installing UFW..."
    apt install ufw -y > /dev/null 2>&1
fi
log_success "UFW is installed."
