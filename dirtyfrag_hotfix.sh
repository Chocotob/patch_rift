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

# 1. ตรวจสอบเวอร์ชัน Kernel
KERNEL_VER=$(uname -r)
KERNEL_BASE=$(echo $KERNEL_VER | cut -d'-' -f1)
echo -e "${PURPLE}[*] Current Kernel:${NC} $KERNEL_VER"

# เกณฑ์ความปลอดภัยเบื้องต้น (ตัวอย่างเลข Patch ที่ปลอดภัย)
# 6.8.5+, 6.6.26+, 6.1.85+
IS_VULN=false
if [[ "$KERNEL_VER" == *"5.15.0-"* ]]; then
    BUILD_NUM=$(echo $KERNEL_VER | cut -d'-' -f2)
    [ "$BUILD_NUM" -lt 111 ] && IS_VULN=true
elif [[ "$KERNEL_VER" == *"6.8.0-"* ]]; then
    BUILD_NUM=$(echo $KERNEL_VER | cut -d'-' -f2)
    [ "$BUILD_NUM" -lt 111 ] && IS_VULN=true
fi

# 2. ตรวจสอบว่า IPv6 เปิดใช้งานอยู่หรือไม่
if [ -f /proc/net/if_inet6 ]; then
    IPV6_ENABLED=true
    echo -e "${YELLOW}[*] IPv6 is currently ENABLED.${NC}"
else
    IPV6_ENABLED=false
    echo -e "${GREEN}[V] IPv6 is DISABLED. Risk is significantly lower.${NC}"
fi

# 3. สรุปผลการตรวจสอบ
if [ "$IS_VULN" = true ] && [ "$IPV6_ENABLED" = true ]; then
    echo -e "${RED}[!] Status: VULNERABLE to DirtyFrag.${NC}"
    
    # 4. ถามเพื่อทำ Workaround
    echo -e "\n${YELLOW}Would you like to apply a Workaround? (y/n)${NC}"
    echo -e "${BLUE}(This will block IPv6 Fragments using ip6tables to close the exploit path)${NC}"
    read -p ">> " CONFIRM
    
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo -e "${YELLOW}[*] Applying ip6tables rule...${NC}"
        
        # บล็อก IPv6 Fragments
        sudo ip6tables -A INPUT -m frag -j DROP
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[V] Workaround applied! IPv6 Fragments are now blocked.${NC}"
            echo -e "${PURPLE}Note: This is a temporary fix. Please plan for a Kernel upgrade later.${NC}"
        else
            echo -e "${RED}[X] Failed to apply ip6tables rule. Please check if ip6tables is installed.${NC}"
        fi
    else
        echo -e "${YELLOW}[!] Workaround cancelled.${NC}"
    fi
else
    echo -e "\n${GREEN}[V] Result: System appears safe or IPv6 is already restricted.${NC}"
fi

echo -e "${BLUE}===================================================${NC}"
