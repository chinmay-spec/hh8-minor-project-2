#!/bin/bash

# ==========================================
# PROJECT: Linux Hardening Script
# AUTHOR: Chinmay
# DATE: $(date)
# ==========================================

echo "🚀 Initializing Hardening Script..."

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERROR: Run as root (sudo ./harden.sh)"
    exit 1
fi
echo "✅ Root privileges confirmed."
