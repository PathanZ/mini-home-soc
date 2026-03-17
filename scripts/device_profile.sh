#!/data/data/com.termux/files/usr/bin/bash

IP="$1"
[ -z "$IP" ] && exit 1

PROFILE_DIR="$HOME/soc/profiles"
LOG_DIR="$HOME/soc/logs"
mkdir -p "$PROFILE_DIR" "$LOG_DIR"

STAMP=$(date '+%Y-%m-%d_%H-%M-%S')
OUT="$PROFILE_DIR/${IP}_${STAMP}.txt"

HOSTNAME=$(getent hosts "$IP" 2>/dev/null | awk '{print $2}' | head -n 1)
[ -z "$HOSTNAME" ] && HOSTNAME="unknown"

DISCOVERY=$(nmap -sn "$IP" 2>/dev/null)
MAC=$(printf '%s\n' "$DISCOVERY" | awk -F'MAC Address: ' '/MAC Address:/{print $2}' | head -n 1)
[ -z "$MAC" ] && MAC="unknown"

PORTS=$(nmap -Pn --top-ports 20 "$IP" 2>/dev/null | awk '/^[0-9]+\/tcp/ {print}')

{
  echo "Device Profile"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "IP: $IP"
  echo "Hostname: $HOSTNAME"
  echo "MAC/Vendor: $MAC"
  echo
  echo "Top Open Ports:"
  if [ -n "$PORTS" ]; then
    echo "$PORTS"
  else
    echo "No open top ports found or host did not respond."
  fi
} > "$OUT"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] PROFILE CREATED: $OUT" >> "$LOG_DIR/device_profiles.log"
