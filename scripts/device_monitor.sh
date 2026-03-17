#!/data/data/com.termux/files/usr/bin/bash

NETWORK=$(ip route | awk '/wlan0/ {print $1; exit}')
LOG_DIR="$HOME/soc/logs"
PROFILE_DIR="$HOME/soc/profiles"
KNOWN="$LOG_DIR/known_devices.txt"
CURRENT="$LOG_DIR/current_devices.txt"
ALERTS="$LOG_DIR/device_alerts.log"

mkdir -p "$LOG_DIR" "$PROFILE_DIR"
touch "$KNOWN" "$ALERTS"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] device_monitor started. Network: $NETWORK"

while true
do
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting discovery scan..."
  nmap -sn "$NETWORK" 2>/dev/null | awk '/Nmap scan report/{print $5}' > "$CURRENT"

  COUNT=$(wc -l < "$CURRENT" 2>/dev/null)
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Discovery complete. Hosts found: $COUNT"

  while read -r ip
  do
    [ -z "$ip" ] && continue

    if ! grep -qx "$ip" "$KNOWN"; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] NEW DEVICE DETECTED: $ip" | tee -a "$ALERTS"
      echo "$ip" >> "$KNOWN"
      bash "$HOME/soc/scripts/device_profile.sh" "$ip"
      bash "$HOME/soc/scripts/gen_dashboard.sh"
    fi
  done < "$CURRENT"

  sleep 600
done
