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

# Configure Default Rules
# Deny all incoming connections (Security First)
ufw default deny incoming > /dev/null 2>&1

# Allow outgoing connections (So the server can run updates)
ufw default allow outgoing > /dev/null 2>&1

log_success "Default firewall policies set (Deny In / Allow Out)."

# Allow SSH Port (Critical: Prevents Lockout)
ufw allow ssh > /dev/null 2>&1
log_success "Allowed SSH traffic."

# Enable the Firewall
# We pipe 'echo y' because enabling UFW usually asks "Are you sure?"
echo "y" | ufw enable > /dev/null 2>&1
log_success "Firewall is now ACTIVE."

# 5. SSH HARDENING
echo "---------------------------------"
echo "🔒 Securing SSH Configuration..."

SSH_CONFIG="/etc/ssh/sshd_config"
BACKUP_CONFIG="/etc/ssh/sshd_config.bak"

# Create a backup if one doesn't exist
if [ ! -f "$BACKUP_CONFIG" ]; then
    cp "$SSH_CONFIG" "$BACKUP_CONFIG"
    log_success "Backup created at $BACKUP_CONFIG"
else
    echo "Backup already exists. Skipping..."
fi

# Disable Root Login
# We use 'sed' to find lines starting with PermitRootLogin (even if commented out)
# and replace them with 'PermitRootLogin no'

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"

log_success "Root login disabled in configuration."

# Restart SSH Service to apply changes
# We try both 'sshd' and 'ssh' because service names vary by OS
if systemctl list-units --full -all | grep -q "sshd.service"; then
    systemctl restart sshd
else
    systemctl restart ssh
fi

log_success "SSH Service restarted. Changes applied."

# 6. REMOVE DANGEROUS SOFTWARE
echo "---------------------------------"
echo "🧹 Reducing Attack Surface..."

# List of packages to remove
# Telnet is insecure; Netcat can be used for reverse shells
BAD_PACKAGES="telnet netcat-openbsd netcat-traditional"

echo "Targeting packages: $BAD_PACKAGES"

# Loop through the list and remove each package
for pkg in $BAD_PACKAGES; do
    # 'apt purge' removes the app AND its config files
    # 2>/dev/null hides the error if the package wasn't installed anyway
    apt purge -y "$pkg" > /dev/null 2>&1

    # Log the action
    echo " - Checked/Removed: $pkg"
done

log_success "Dangerous packages removed."

# Verify removal
# We use 'dpkg -l' to list installed apps and grep for our bad ones
if dpkg -l | grep -qE "telnet|netcat"; then
    log_error "Warning: Some dangerous packages might still remain."
else
    log_success "Verification Passed: System is clean."
fi

# 7. INTRUSION PREVENTION (Fail2Ban)
echo "---------------------------------"
echo "🕵️  Setting up Intrusion Prevention (Fail2Ban)..."

# Install Fail2Ban
if ! command -v fail2ban-client &> /dev/null; then
    echo "Installing Fail2Ban..."
    apt install fail2ban -y > /dev/null 2>&1
fi
log_success "Fail2Ban installed."

# Create a safe configuration copy
# We copy jail.conf to jail.local so our changes survive updates
if [ ! -f /etc/fail2ban/jail.local ]; then
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    log_success "Created jail.local configuration."
fi

# Configure SSH Jail (Ban repeated failed login attempts)
# We use 'sed' to ensure the SSH jail is enabled
sed -i 's/^\[sshd\]/[sshd]\nenabled = true/' /etc/fail2ban/jail.local

log_success "Configured SSH protection rules."

# Restart and Enable Fail2Ban Service
systemctl restart fail2ban
systemctl enable fail2ban > /dev/null 2>&1

# Check status
if systemctl is-active --quiet fail2ban; then
    log_success "Fail2Ban is active and watching."
else
    log_error "Fail2Ban failed to start."
fi

# 8. NETWORK HARDENING (Disable IPv6)
echo "---------------------------------"
echo "🌐 Disabling unused protocols..."

# Disable IPv6 to reduce attack surface
# We write these settings to a config file so they persist after reboot
CONF_FILE="/etc/sysctl.d/99-disable-ipv6.conf"
if [ ! -f "$CONF_FILE" ]; then
    echo "net.ipv6.conf.all.disable_ipv6 = 1" > "$CONF_FILE"
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> "$CONF_FILE"
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> "$CONF_FILE"
    sysctl -p "$CONF_FILE" > /dev/null 2>&1
    log_success "IPv6 disabled."
else
    echo "IPv6 already disabled."
fi

# 9. SECURITY AUDIT (Empty Passwords)
echo "---------------------------------"
echo "🕵️  Auditing User Accounts..."

# Check for users with empty password fields in /etc/shadow
EMPTY_PASS=$(awk -F: '($2 == "" ) { print $1 }' /etc/shadow)

if [ -z "$EMPTY_PASS" ]; then
    log_success "No users with empty passwords found."
else
    log_error "WARNING: The following users have no password: $EMPTY_PASS"
    log_error "Please set a password for them immediately using 'passwd <user>'."
fi

# 10. FINAL SUMMARY
echo "---------------------------------"
echo "✅ HARDENING COMPLETE!"
echo "Summary of actions:"
echo " - System Updated"
echo " - Firewall Configured"
echo " - SSH Hardened"
echo " - Dangerous Apps Removed"
echo " - Fail2Ban Installed"
echo " - Network Protocols Secured"
echo "---------------------------------"
echo "Please reboot your system to ensure all changes take effect."
