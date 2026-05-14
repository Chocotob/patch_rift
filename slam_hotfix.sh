#!/bin/bash

# --- Color Definitions ---
RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
NC='\033[0m' 

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}   SLAM / Spectre-BHI Temporary Hotfix (Prod)      ${NC}"
echo -e "${BLUE}===================================================${NC}"

# 1. ตรวจสอบความเสี่ยงจาก Kernel Report
echo -e "${YELLOW}[*] Checking CPU Vulnerabilities status...${NC}"
if [ -f /sys/devices/system/cpu/vulnerabilities/spectre_v2 ]; then
    STATUS=$(cat /sys/devices/system/cpu/vulnerabilities/spectre_v2)
    echo -e "${BLUE}[+] Current Status:${NC} $STATUS"
    
    if [[ "$STATUS" == *"Vulnerable"* ]]; then
        IS_VULN=true
        echo -e "${RED}[!] System is VULNERABLE.${NC}"
    else
        IS_VULN=false
        echo -e "${GREEN}[V] System is NOT VULNERABLE or already mitigated.${NC}"
    fi
else
    echo -e "${RED}[!] Cannot find vulnerability info. Kernel too old.${NC}"
    IS_VULN=true
fi

# 2. ถ้าเสี่ยง ให้ถามเพื่อทำ Hotfix (Disable algif_aead)
if [ "$IS_VULN" = true ]; then
    echo -e "\n${YELLOW}Action: Disable 'algif_aead' module to block exploit path? (y/n)${NC}"
    echo -e "${BLUE}(This is a temporary fix that doesn't require Reboot)${NC}"
    read -p ">> " CONFIRM
    
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo -e "${YELLOW}[*] Applying Hotfix...${NC}"
        
        # ป้องกันไม่ให้โหลด Module เมื่อ Reboot ครั้งหน้า
        echo "install algif_aead /bin/false" | sudo tee /etc/modprobe.d/disable-algif.conf > /dev/null
        
        # สั่งถอด Module ออกจาก Runtime ปัจจุบัน
        sudo rmmod algif_aead 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[V] Hotfix applied successfully. 'algif_aead' is disabled.${NC}"
        else
            echo -e "${YELLOW}[!] Module 'algif_aead' was not loaded or could not be removed.${NC}"
            echo -e "${BLUE}[*] Config file created. It will take effect on next boot.${NC}"
        fi
        
        echo -e "\n${PURPLE}Note: Please plan for a full Kernel Upgrade and Reboot later.${NC}"
    else
        echo -e "${YELLOW}[!] Hotfix cancelled.${NC}"
    fi
else
    echo -e "\n${GREEN}Result: No immediate action needed for SLAM on this machine.${NC}"
fi

echo -e "${BLUE}===================================================${NC}"
