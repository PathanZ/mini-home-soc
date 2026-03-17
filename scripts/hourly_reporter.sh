#!/data/data/com.termux/files/usr/bin/bash

LOG_DIR="$HOME/soc/logs"
mkdir -p "$LOG_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] hourly_reporter started."

while true
do
  REPORT_PATH=$(bash "$HOME/soc/scripts/report_builder.sh")
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] REPORT CREATED: $REPORT_PATH" >> "$LOG_DIR/report_runner.log"

  bash "$HOME/soc/scripts/gen_dashboard.sh"

  sleep 3600
done
