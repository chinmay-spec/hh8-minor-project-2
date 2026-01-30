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
