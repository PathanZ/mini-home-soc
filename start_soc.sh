#!/data/data/com.termux/files/usr/bin/bash

# ── start_soc.sh ──────────────────────────────────────────
# Run this once after every reboot to bring the full SOC up.
# All scripts run in named tmux windows inside one session.
#
# To check on things:
#   tmux attach -t soc
#   Ctrl+B then W  to see all windows
#   Ctrl+B then D  to detach
# ─────────────────────────────────────────────────────────

SESSION="soc"

# Kill any existing session cleanly
tmux kill-session -t "$SESSION" 2>/dev/null
sleep 1

# Create folders just in case
mkdir -p "$HOME/soc/scripts" \
         "$HOME/soc/logs" \
         "$HOME/soc/profiles" \
         "$HOME/soc/reports" \
         "$HOME/soc/www" \
         "$HOME/tailscale-state"

# Start tmux session with first window: tailscale
tmux new-session -d -s "$SESSION" -n "tailscale" \
  "bash $HOME/soc/scripts/start_tailscale.sh; bash"

# Window 2: device monitor
tmux new-window -t "$SESSION" -n "monitor" \
  "bash $HOME/soc/scripts/device_monitor.sh; bash"

# Window 3: port scanner
tmux new-window -t "$SESSION" -n "scanner" \
  "bash $HOME/soc/scripts/scan_detector.sh; bash"

# Window 4: hourly reporter
tmux new-window -t "$SESSION" -n "reporter" \
  "bash $HOME/soc/scripts/hourly_reporter.sh; bash"

# Window 5: dashboard server
tmux new-window -t "$SESSION" -n "dashboard" \
  "bash $HOME/soc/scripts/start_dashboard.sh; bash"

echo "SOC started. All windows running in tmux session: $SESSION"
echo ""
echo "To attach:       tmux attach -t soc"
echo "To list windows: Ctrl+B then W"
echo "To detach:       Ctrl+B then D"
echo ""
echo "Dashboard: http://100.108.246.93:8080"
