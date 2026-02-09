# Linux Server Hardening Script 🛡️

## Project Description
This project is a Bash script designed to automate the initial security setup of a Linux server. It implements industry-standard security practices to reduce the attack surface and protect against common threats.

## Features
* **System Updates:** Automates `apt update` and `upgrade`.
* **Firewall (UFW):** Configures default deny policies and allows only SSH.
* **SSH Hardening:** Disables Root Login and enforces secure access.
* **Intrusion Prevention:** Installs and configures **Fail2Ban** to block brute-force attacks.
* **Attack Surface Reduction:** Removes insecure packages (Telnet, Netcat).
* **Network Hardening:** Disables IPv6 to prevent unauthorized traffic.
* **Auditing:** Scans for users with empty passwords.

## Usage
1.  Clone the repository.
2.  Make the script executable: `chmod +x harden.sh`
3.  Run as root: `sudo ./harden.sh`

## Author
Chinmay
