#!/data/data/com.termux/files/usr/bin/bash

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Tailscale..."

pkill tailscaled 2>/dev/null
sleep 2
rm -f $TMPDIR/tailscaled.sock

tailscaled --tun=userspace-networking \
           --state=$HOME/tailscale-state/tailscaled.state \
           --socket=$TMPDIR/tailscaled.sock &

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for tailscaled to start..."
sleep 5

tailscale --socket=$TMPDIR/tailscaled.sock up --accept-routes 2>/dev/null

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tailscale IP: $(tailscale --socket=$TMPDIR/tailscaled.sock ip 2>/dev/null)"

# Keep the script alive so tmux window stays open
wait
