#!/bin/bash

# --- Color Definitions ---
RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
NC='\033[0m' 

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}   CPU Side-Channel Audit (SLAM / Spectre-BHI)     ${NC}"
echo -e "${BLUE}===================================================${NC}"

# 1. ตรวจสอบสถานะจาก System File โดยตรง (แม่นยำที่สุด)
echo -e "${YELLOW}[*] Checking CPU Vulnerabilities status...${NC}"

# ตรวจสอบ Spectre V2 (รวม BHI/SLAM)
if [ -f /sys/devices/system/cpu/vulnerabilities/spectre_v2 ]; then
    STATUS=$(cat /sys/devices/system/cpu/vulnerabilities/spectre_v2)
    echo -e "${BLUE}[+] Spectre v2 Status:${NC} $STATUS"
    
    if [[ "$STATUS" == *"Vulnerable"* ]] || [[ "$STATUS" == *"Mitigation: Optional"* ]]; then
        IS_VULN=true
    else
        IS_VULN=false
    fi
else
    echo -e "${RED}[!] Cannot find vulnerability info. Kernel might be too old.${NC}"
    IS_VULN=true
fi

# 2. สรุปผล
if [ "$IS_VULN" = true ]; then
    echo -e "\n${RED}[!!!] RISK DETECTED: This system is vulnerable to SLAM/Spectre-BHI.${NC}"
    echo -e "${YELLOW}Explanation: Attackers could potentially leak sensitive data from kernel memory.${NC}"
    
    # 3. ส่วนการแก้ไข
    echo -e "\n${BLUE}--- Remediation Strategy ---${NC}"
    echo -e "1. Update Linux Kernel to the latest version."
    echo -e "2. Update CPU Microcode (intel-microcode / amd64-microcode)."
    echo -e "3. Apply kernel boot parameters (e.g., spectre_v2=on)."

    read -p "Do you want to attempt an automatic update (Kernel & Microcode)? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo -e "${YELLOW}[*] Updating system packages...${NC}"
        sudo apt update
        # ติดตั้ง Microcode ล่าสุดและอัปเกรด Kernel
        sudo apt install -y intel-microcode amd64-microcode
        sudo apt dist-upgrade -y
        
        echo -e "${GREEN}[+] Update process finished.${NC}"
        echo -e "${RED}[!] IMPORTANT: You MUST reboot the system to apply Kernel & Microcode changes.${NC}"
        
        read -p "Reboot now? (y/n): " REBOOT_NOW
        if [[ "$REBOOT_NOW" == "y" || "$REBOOT_NOW" == "Y" ]]; then
            sudo reboot
        fi
    else
        echo -e "${YELLOW}[*] Update cancelled. Please monitor this machine manually.${NC}"
    fi
else
    echo -e "\n${GREEN}[V] SECURE: Mitigation is active or CPU is not affected.${NC}"
fi

echo -e "${BLUE}===================================================${NC}"
