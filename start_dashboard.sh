#!/data/data/com.termux/files/usr/bin/bash

WWW_DIR="$HOME/soc/www"
PORT=8080

mkdir -p "$WWW_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating dashboard..."
bash "$HOME/soc/scripts/gen_dashboard.sh"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting HTTP server on port $PORT"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Access via Tailscale: http://100.108.246.93:$PORT"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Local access: http://localhost:$PORT"

cd "$WWW_DIR" && python -m http.server $PORT
