#!/bin/bash

# --- Color Definitions ---
RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
NC='\033[0m' 

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}       All-in-One Security Patch (Prod-Safe)       ${NC}"
echo -e "${BLUE}    NGINX Rift | Copy Fail Hotfix | DirtyFrag Hotfix    ${NC}"
echo -e "${BLUE}===================================================${NC}"

# ตรวจสอบสิทธิ์ Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[X] Please run as root (sudo bash mega_patch.sh)${NC}"
   exit 1
fi

# ตรวจสอบ OS
OS_VER=$(lsb_release -rs)
OS_CODENAME=$(lsb_release -cs)
echo -e "${PURPLE}[*] OS detected: Ubuntu $OS_VER ($OS_CODENAME)${NC}"

# ---------------------------------------------------------
# SECTION 1: NGINX Rift (CVE-2026-42945)
# ---------------------------------------------------------
echo -e "\n${YELLOW}--- [1/3] NGINX Rift Security Audit ---${NC}"
if command -v nginx >/dev/null 2>&1; then
    NGINX_PKG_VER=$(dpkg -l | grep nginx-common | awk '{print $3}')
    SAFE=false

    # ตรวจสอบเลข Revision อย่างละเอียด (รองรับเลขใหม่ๆ เช่น .11)
    REV=$(echo "$NGINX_PKG_VER" | sed 's/.*ubuntu//' | cut -d'.' -f2)
    
    case "$OS_VER" in
        "24.04") [[ "$NGINX_PKG_VER" == *"ubuntu7.8"* ]] || [ "$REV" -gt 8 ] && SAFE=true ;;
        "22.04") [[ "$NGINX_PKG_VER" == *"ubuntu14.6"* ]] || [ "$REV" -ge 11 ] && SAFE=true ;;
        "20.04") [[ "$NGINX_PKG_VER" == *"ubuntu1.7"* ]] || [ "$REV" -gt 7 ] && SAFE=true ;;
    esac

    if [ "$SAFE" = true ]; then
        echo -e "${GREEN}[V] NGINX is SAFE (Version: $NGINX_PKG_VER)${NC}"
    else
        echo -e "${RED}[X] NGINX is VULNERABLE (Version: $NGINX_PKG_VER)${NC}"
        read -p "Upgrade NGINX now? (y/n): " UP_NGINX < /dev/tty
        if [[ "$UP_NGINX" == "y" ]]; then
            apt update && apt install -y nginx
            echo -e "${GREEN}[+] NGINX Upgrade complete.${NC}"
        fi
    fi
else
    echo -e "${BLUE}[-] NGINX not installed. Skipping.${NC}"
fi

# ---------------------------------------------------------
# SECTION 2: Copy Fail Hotfix
# ---------------------------------------------------------
echo -e "\n${YELLOW}--- [2/3] Copy Fail Hotfix ---${NC}"
STATUS_V2=$(cat /sys/devices/system/cpu/vulnerabilities/spectre_v2 2>/dev/null)

if [[ "$STATUS_V2" == *"Vulnerable"* ]]; then
    echo -e "${RED}[!] System is VULNERABLE to Copy Fail.${NC}"
    read -p "Apply Hotfix (Disable algif_aead)? (y/n): " UP_COPYFAIL < /dev/tty
    if [[ "$UP_COPYFAIL" == "y" ]]; then
        echo "install algif_aead /bin/false" > /etc/modprobe.d/disable-algif.conf
        rmmod algif_aead 2>/dev/null
        echo -e "${GREEN}[V] Copy Fail Hotfix applied.${NC}"
    fi
else
    echo -e "${GREEN}[V] Copy Fail Status: $STATUS_V2 (Safe or Mitigated)${NC}"
fi

# ---------------------------------------------------------
# SECTION 3: DirtyFrag (CVE-2026-38294)
# ---------------------------------------------------------
echo -e "\n${YELLOW}--- [3/3] DirtyFrag Security Hotfix ---${NC}"
# ตรวจสอบว่าโมดูล esp4/esp6 ยังอยู่ไหม
if lsmod | grep -qE "esp4|esp6|rxrpc"; then
    echo -e "${RED}[!] System is potentially vulnerable to DirtyFrag.${NC}"
    read -p "Apply Module Blacklist (esp4, esp6, rxrpc)? (y/n): " UP_DF < /dev/tty
    if [[ "$UP_DF" == "y" ]]; then
        sh -c "printf 'install esp4 /bin/false\ninstall esp6 /bin/false\ninstall rxrpc /bin/false\n' > /etc/modprobe.d/dirtyfrag.conf"
        rmmod esp4 esp6 rxrpc 2>/dev/null
        echo 3 > /proc/sys/vm/drop_caches
        echo -e "${GREEN}[V] DirtyFrag Workaround applied.${NC}"
    fi
else
    echo -e "${GREEN}[V] DirtyFrag: Exploit paths are already restricted.${NC}"
fi

echo -e "\n${BLUE}===================================================${NC}"
echo -e "${BLUE}         All checks completed. Stay safe!          ${NC}"
echo -e "${BLUE}===================================================${NC}"
