#!/bin/bash

# --- Color Definitions ---
RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
NC='\033[0m' 

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}     DirtyFrag (CVE-2026-38294) Security Audit     ${NC}"
echo -e "${BLUE}===================================================${NC}"

# 1. ตรวจสอบเวอร์ชัน Kernel ปัจจุบัน
KERNEL_FULL=$(uname -r)
KERNEL_BASE=$(uname -r | cut -d'-' -f1)
echo -e "${BLUE}[*] Current Kernel:${NC} $KERNEL_FULL"

# 2. ฟังก์ชันตรวจสอบความเสี่ยง (อ้างอิงตามเลขเวอร์ชันที่ได้รับ Patch)
# ช่องโหว่นี้กระทบ Kernel หลายสาย หลักๆ คือต้องอัปเดตให้สูงกว่า:
# 6.8.5, 6.6.26, 6.1.85 หรือแพตช์เฉพาะของ Distribution
IS_VULNERABLE=false

# ตรวจสอบเบื้องต้น (สำหรับ Ubuntu มักจะดูที่เลขรหัสตัวหลัง -xxx)
if [[ "$KERNEL_FULL" == *"6.8.0-"* ]]; then
    # สำหรับ Ubuntu 24.04 (Noble) เลขที่ปลอดภัยมักจะเป็น -111 ขึ้นไป
    BUILD_NUM=$(echo $KERNEL_FULL | cut -d'-' -f2)
    if [ "$BUILD_NUM" -lt 111 ]; then
        IS_VULNERABLE=true
    fi
elif [[ "$KERNEL_FULL" == *"5.15.0-"* ]]; then
    # สำหรับ Ubuntu 22.04 (Jammy)
    BUILD_NUM=$(echo $KERNEL_FULL | cut -d'-' -f2)
    if [ "$BUILD_NUM" -lt 105 ]; then # เลขสมมติฐานเบื้องต้น
        IS_VULNERABLE=true
    fi
fi

# 3. ตรวจสอบว่ามีการโหลดโมดูล IPv6 ไหม (เพราะ DirtyFrag โจมตีผ่าน IPv6)
if [ -f /proc/net/if_inet6 ]; then
    echo -e "${YELLOW}[*] IPv6 is enabled on this system.${NC}"
    IPV6_ACTIVE=true
else
    echo -e "${GREEN}[*] IPv6 is disabled. Risk is lower but update is still recommended.${NC}"
    IPV6_ACTIVE=false
fi

# 4. สรุปผล
if [ "$IS_VULNERABLE" = true ]; then
    echo -e "\n${RED}[!!!] WARNING: System is potentially vulnerable to DirtyFrag.${NC}"
    
    echo -e "\n${BLUE}--- Remediation ---${NC}"
    read -p "Do you want to perform a full system upgrade (Kernel update)? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo -e "${YELLOW}[*] Running dist-upgrade to update Kernel...${NC}"
        sudo apt update
        sudo apt dist-upgrade -y
        
        echo -e "${GREEN}[+] Upgrade complete.${NC}"
        echo -e "${RED}[!] A system REBOOT is required to load the new Kernel.${NC}"
        
        read -p "Reboot now? (y/n): " REBOOT_NOW
        if [[ "$REBOOT_NOW" == "y" || "$REBOOT_NOW" == "Y" ]]; then
            sudo reboot
        fi
    fi
else
    echo -e "\n${GREEN}[V] SECURE: Kernel version appears to be patched.${NC}"
fi

echo -e "${BLUE}===================================================${NC}"
