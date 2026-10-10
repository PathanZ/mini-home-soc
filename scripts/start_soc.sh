#!/data/data/com.termux/files/usr/bin/bash

# ── start_soc.sh ──────────────────────────────────────────
# Run this once after every reboot to bring the full SOC up.
# All scripts run in named tmux windows inside one session.
#
# Tailscale runs through the official Android app (no root
# needed), so it is not started here. On older devices that
# need the Termux Tailscale workaround, see start_tailscale.sh.
#
# To check on things:
#   tmux attach -t soc
#   Ctrl+B then W  to see all windows
#   Ctrl+B then D  to detach
# ─────────────────────────────────────────────────────────

SESSION="soc"

# Set this to your phone's Tailscale IP (shown in the Tailscale app)
TS_IP="CHANGE_ME"

# Keep Android from putting Termux to sleep
termux-wake-lock 2>/dev/null

# Kill any existing session cleanly
tmux kill-session -t "$SESSION" 2>/dev/null
sleep 1

# Create folders just in case
mkdir -p "$HOME/soc/scripts" \
         "$HOME/soc/logs" \
         "$HOME/soc/profiles" \
         "$HOME/soc/reports" \
         "$HOME/soc/www"

# Window 1: device monitor
tmux new-session -d -s "$SESSION" -n "monitor" \
  "bash $HOME/soc/scripts/device_monitor.sh; bash"

# Window 2: port scanner
tmux new-window -t "$SESSION" -n "scanner" \
  "bash $HOME/soc/scripts/scan_detector.sh; bash"

# Window 3: hourly reporter
tmux new-window -t "$SESSION" -n "reporter" \
  "bash $HOME/soc/scripts/hourly_reporter.sh; bash"

# Window 4: dashboard server
tmux new-window -t "$SESSION" -n "dashboard" \
  "bash $HOME/soc/scripts/start_dashboard.sh; bash"

LOCAL_IP=$(ip route 2>/dev/null | awk '/wlan0/ {for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')

echo "SOC started. All windows running in tmux session: $SESSION"
echo ""
echo "To attach:       tmux attach -t soc"
echo "To list windows: Ctrl+B then W"
echo "To detach:       Ctrl+B then D"
echo ""
echo "Dashboard (Tailscale):  http://$TS_IP:8080"
echo "Dashboard (home Wi-Fi): http://${LOCAL_IP:-<phone-local-ip>}:8080"
