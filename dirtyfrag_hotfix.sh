#!/bin/bash

# --- Color Definitions ---
RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
NC='\033[0m' 

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}      DirtyFrag (CVE-2026-38294) Hotfix Script     ${NC}"
echo -e "${BLUE}===================================================${NC}"

# 1. ตรวจสอบเวอร์ชัน Kernel (อ้างอิงจากข้อมูลล่าสุด)
KERNEL_VER=$(uname -r)
echo -e "${PURPLE}[*] Current Kernel:${NC} $KERNEL_VER"

# เครื่องที่รัน Kernel ต่ำกว่า 6.8.5 หรือแพตช์ล่าสุดถือว่าเสี่ยง
IS_VULN=true
if [[ "$KERNEL_VER" == *"6.8.0-111"* ]] || [[ "$KERNEL_VER" == *"1.18.0-6ubuntu14.11"* ]]; then
    IS_VULN=false
fi

# 2. ตรวจสอบความเสี่ยง
if [ "$IS_VULN" = true ]; then
    echo -e "${RED}[!] Status: VULNERABLE to DirtyFrag.${NC}"
    
    # 3. ถามเพื่อทำ Workaround (Module Blacklisting)
    echo -e "\n${YELLOW}Would you like to apply the Module Blacklist workaround? (y/n)${NC}"
    echo -e "${BLUE}(This will disable esp4, esp6, and rxrpc to close exploit paths)${NC}"
    
    # ใช้ /dev/tty เพื่อให้รองรับการรันผ่าน curl | bash
    read -p ">> " CONFIRM < /dev/tty
    
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo -e "${YELLOW}[*] Applying Module Blacklist and dropping caches...${NC}"
        
        # รันคำสั่งที่คุณแนะนำ
        sudo sh -c "printf 'install esp4 /bin/false\ninstall esp6 /bin/false\ninstall rxrpc /bin/false\n' > /etc/modprobe.d/dirtyfrag.conf; rmmod esp4 esp6 rxrpc 2>/dev/null; echo 3 > /proc/sys/vm/drop_caches; true"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[V] Workaround applied successfully!${NC}"
            echo -e "${PURPLE}Note: Exploit paths are now restricted without Reboot.${NC}"
        else
            echo -e "${RED}[X] Something went wrong during the process.${NC}"
        fi
    else
        echo -e "${YELLOW}[!] Workaround cancelled.${NC}"
    fi
else
    echo -e "\n${GREEN}[V] Result: System appears to be patched or running a secure kernel.${NC}"
fi

echo -e "${BLUE}===================================================${NC}"
