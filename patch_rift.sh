#!/bin/bash

# --- Color Definitions ---
RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   NGINX Rift (CVE-2026-42945) Security Audit  ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. ตรวจสอบ OS Version
OS_DISTRO=$(lsb_release -is)
OS_RELEASE=$(lsb_release -rs)
OS_CODENAME=$(lsb_release -cs)
echo -e "${PURPLE}[*] OS:${NC} $OS_DISTRO $OS_RELEASE ($OS_CODENAME)"

# 2. ตรวจสอบ NGINX Version ย่อย (DPKG)
if ! command -v nginx >/dev/null 2>&1; then
    echo -e "${RED}[!] NGINX is not installed on this system.${NC}"
    exit 1
fi

NGINX_PKG_VER=$(dpkg -l | grep "^ii  nginx " | awk '{print $3}')
echo -e "${PURPLE}[*] NGINX Package:${NC} $NGINX_PKG_VER"

# 3. กำหนดเกณฑ์ความปลอดภัย (Safe Versions)
SAFE=false
case "$OS_RELEASE" in
    "24.04")
        [[ "$NGINX_PKG_VER" == *"2ubuntu7.8"* ]] && SAFE=true
        ;;
    "22.04")
        [[ "$NGINX_PKG_VER" == *"6ubuntu14.6"* ]] && SAFE=true
        ;;
    "20.04")
        [[ "$NGINX_PKG_VER" == *"0ubuntu1.7"* ]] && SAFE=true
        ;;
esac

# 4. ตรวจสอบความเสี่ยงใน Config (The "Rift" Condition)
echo -e "${PURPLE}[*] Checking Config Vulnerability...${NC}"
VULN_CONFIG=$(grep -r "rewrite" /etc/nginx | grep "\?" | grep "\$")

if [ "$SAFE" = true ]; then
    echo -e "${GREEN}[V] Binary Status: SECURE (Patched)${NC}"
else
    echo -e "${RED}[X] Binary Status: VULNERABLE (Needs Update)${NC}"
fi

if [ -n "$VULN_CONFIG" ]; then
    echo -e "${RED}[X] Config Status: RISKY (Dangerous rewrite rules found)${NC}"
    echo -e "${YELLOW}$VULN_CONFIG${NC}"
else
    echo -e "${GREEN}[V] Config Status: CLEAN (No dangerous rewrite patterns)${NC}"
fi

# 5. ถามเพื่ออัปเกรด
if [ "$SAFE" = false ]; then
    echo -e "\n${YELLOW}Would you like to upgrade NGINX now? (y/n)${NC}"
    read -p ">> " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo -e "${BLUE}[+] Starting Upgrade...${NC}"
        sudo apt update
        sudo apt install --only-upgrade nginx -y
        
        # ตรวจสอบหลังอัปเกรด
        NEW_VER=$(dpkg -l | grep "^ii  nginx " | awk '{print $3}')
        echo -e "${GREEN}[+] Upgrade Complete. New Version: $NEW_VER${NC}"
        
        # ตรวจสอบสถานะอีกครั้ง
        sudo nginx -t && sudo systemctl restart nginx
        echo -e "${GREEN}[V] NGINX Restarted successfully.${NC}"
    else
        echo -e "${YELLOW}[!] Upgrade cancelled.${NC}"
    fi
else
    echo -e "\n${GREEN}Result: Your system is already patched against NGINX Rift.${NC}"
fi

echo -e "${BLUE}===============================================${NC}"