#!/data/data/com.termux/files/usr/bin/bash

NETWORK=$(ip route | awk '/wlan0/ {print $1; exit}')
LOG_DIR="$HOME/soc/logs"
SCAN_LOG="$LOG_DIR/scan_activity.log"

mkdir -p "$LOG_DIR"
touch "$SCAN_LOG"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] scan_detector started. Network: $NETWORK"

while true
do
  {
    echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="
    nmap -Pn --top-ports 20 "$NETWORK"
    echo
  } >> "$SCAN_LOG" 2>&1

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Port scan complete."
  sleep 3600
done
