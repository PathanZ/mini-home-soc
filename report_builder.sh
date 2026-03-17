#!/data/data/com.termux/files/usr/bin/bash

REPORT_DIR="$HOME/soc/reports"
LOG_DIR="$HOME/soc/logs"
PROFILE_DIR="$HOME/soc/profiles"

mkdir -p "$REPORT_DIR"

STAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT="$REPORT_DIR/hourly_report_$STAMP.txt"

CURRENT_COUNT=0
KNOWN_COUNT=0
ALERT_COUNT=0
PROFILE_COUNT=0

[ -f "$LOG_DIR/current_devices.txt" ] && CURRENT_COUNT=$(wc -l < "$LOG_DIR/current_devices.txt")
[ -f "$LOG_DIR/known_devices.txt" ]   && KNOWN_COUNT=$(wc -l < "$LOG_DIR/known_devices.txt")
[ -f "$LOG_DIR/device_alerts.log" ]   && ALERT_COUNT=$(grep -c "NEW DEVICE" "$LOG_DIR/device_alerts.log" 2>/dev/null || echo 0)
PROFILE_COUNT=$(find "$PROFILE_DIR" -type f 2>/dev/null | wc -l)

{
  echo "Mini Home SOC Hourly Report"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "Summary"
  echo "-------"
  echo "Current active devices : $CURRENT_COUNT"
  echo "Known devices          : $KNOWN_COUNT"
  echo "New device alerts      : $ALERT_COUNT"
  echo "Saved device profiles  : $PROFILE_COUNT"
  echo

  echo "Current Devices"
  echo "---------------"
  if [ -f "$LOG_DIR/current_devices.txt" ]; then
    cat "$LOG_DIR/current_devices.txt"
  else
    echo "No current device file yet."
  fi
  echo

  echo "Recent New Device Alerts"
  echo "------------------------"
  if [ -f "$LOG_DIR/device_alerts.log" ]; then
    tail -n 20 "$LOG_DIR/device_alerts.log"
  else
    echo "No alerts yet."
  fi
  echo

  echo "Recent Profile Events"
  echo "---------------------"
  if [ -f "$LOG_DIR/device_profiles.log" ]; then
    tail -n 10 "$LOG_DIR/device_profiles.log"
  else
    echo "No profile events yet."
  fi
  echo

  echo "Recent Port Visibility Scan"
  echo "---------------------------"
  if [ -f "$LOG_DIR/scan_activity.log" ]; then
    tail -n 60 "$LOG_DIR/scan_activity.log"
  else
    echo "No scan activity yet."
  fi
} > "$REPORT"

echo "$REPORT"
