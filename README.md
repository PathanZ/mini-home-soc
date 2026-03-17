# Mini Home SOC — Android Network Sensor + Dashboard

A lightweight Security Operations Center built on a low-end Android phone running 24/7 as a home network sensor. Monitors devices, detects new connections, scans ports, and serves a responsive dashboard accessible from anywhere via Tailscale.

---

## What it does

- Discovers all devices on the home network every 10 minutes
- Fingerprints every new device — IP, open ports, first seen timestamp
- Scans 7 security-critical ports across the entire network every hour
- Alerts on new unknown devices joining the network
- Generates hourly reports summarizing network state
- Serves a responsive dark-theme dashboard over a zero-trust private network

---

## Architecture

```
Internet
    │
    │
┌─────────────┐
│  Tailscale  │
│ private net │
└──────┬──────┘
       │
┌──────┼──────────────┐
│      │              │
Laptop  Main Phone   Sensor Phone (ZTE L210)
                           │
                           │
                 ┌─────────────────┐
                 │  SOC Dashboard  │
                 │  Static HTML    │
                 │  python http    │
                 └────────┬────────┘
                          │
                  ┌───────────────┐
                  │  Monitoring   │
                  │  Scripts      │
                  │  nmap scans   │
                  └───────────────┘
```

---

## Hardware

| Device | Spec |
|--------|------|
| ZTE Blade L210 | ARMv7, 256MB RAM |
| OS | Android 10 Go Edition |
| Runtime | Termux |
| Network | Home WiFi (wlan0) |

---

## Stack

- Android + Termux
- Bash scripting
- nmap
- Python http.server
- Tailscale (WireGuard, userspace-networking mode)
- HTML / CSS
- tmux

---

## Folder Structure

```
~/soc/
├── scripts/
│   ├── device_monitor.sh       # discovery scan every 10 min
│   ├── device_profile.sh       # fingerprints new devices
│   ├── scan_detector.sh        # port scan every 1 hour
│   ├── report_builder.sh       # builds hourly text report
│   ├── hourly_reporter.sh      # runs report builder loop
│   ├── gen_dashboard.sh        # generates static HTML dashboard
│   ├── start_dashboard.sh      # starts Python HTTP server
│   ├── start_tailscale.sh      # starts Tailscale daemon
│   └── start_soc.sh            # master launcher
├── logs/
│   ├── known_devices.txt
│   ├── current_devices.txt
│   ├── device_alerts.log
│   ├── device_profiles.log
│   ├── scan_activity.log
│   └── report_runner.log
├── profiles/                   # per-device profile files
├── reports/                    # hourly report files
└── www/
    └── index.html              # generated dashboard
```

---

## Setup Guide

### Step 1 — Install Termux

Install Termux from F-Droid (not Play Store — the Play Store version is abandoned):
```
https://f-droid.org/packages/com.termux/
```

### Step 2 — Install packages

```bash
pkg update && pkg upgrade -y
pkg install nmap python tmux curl -y
```

### Step 3 — Create folder structure

```bash
mkdir -p ~/soc/{scripts,logs,profiles,reports,www}
mkdir -p ~/tailscale-state
```

### Step 4 — Create all scripts

Create each script using nano:

```bash
nano ~/soc/scripts/device_monitor.sh
nano ~/soc/scripts/device_profile.sh
nano ~/soc/scripts/scan_detector.sh
nano ~/soc/scripts/report_builder.sh
nano ~/soc/scripts/hourly_reporter.sh
nano ~/soc/scripts/gen_dashboard.sh
nano ~/soc/scripts/start_dashboard.sh
nano ~/soc/scripts/start_tailscale.sh
nano ~/soc/scripts/start_soc.sh
```

Paste the contents of each script from the `scripts/` folder in this repository.

Save each file with `Ctrl+O` then `Enter` then `Ctrl+X`.

### Step 5 — Make scripts executable

```bash
chmod +x ~/soc/scripts/*.sh
```

### Step 6 — Install Tailscale

The ZTE L210 runs kernel 4.14 which does not support TUN. Use userspace-networking mode with an older Tailscale binary:

```bash
cd ~
wget https://pkgs.tailscale.com/stable/tailscale_1.32.3_arm.tgz
tar -xzf tailscale_1.32.3_arm.tgz
cd tailscale_1.32.3_arm
cp tailscale tailscaled $PREFIX/bin/
chmod +x $PREFIX/bin/tailscale $PREFIX/bin/tailscaled
```

### Step 7 — Authenticate Tailscale

In one Termux session start the daemon:

```bash
tailscaled --tun=userspace-networking \
           --state=$HOME/tailscale-state/tailscaled.state \
           --socket=$TMPDIR/tailscaled.sock
```

In a second Termux session authenticate:

```bash
tailscale --socket=$TMPDIR/tailscaled.sock up
```

Open the printed URL in your browser and sign in. Then confirm your Tailscale IP:

```bash
tailscale --socket=$TMPDIR/tailscaled.sock ip
```

### Step 8 — Launch everything

```bash
bash ~/soc/scripts/start_soc.sh
```

This starts 5 tmux windows:
- `tailscale` — Tailscale daemon
- `monitor` — device discovery
- `scanner` — port scanning
- `reporter` — hourly reports
- `dashboard` — HTTP server on port 8080

### Step 9 — Access the dashboard

From any device on your Tailscale network:
```
http://<your-tailscale-ip>:8080
```

On the same local network:
```
http://<phone-local-ip>:8080
```

### Step 10 — Backfill device profiles

On first run, profile all already-known devices:

```bash
while read -r ip; do
  bash ~/soc/scripts/device_profile.sh "$ip"
done < ~/soc/logs/known_devices.txt

bash ~/soc/scripts/gen_dashboard.sh
```

---

## After a reboot

```bash
bash ~/soc/scripts/start_soc.sh
```

---

## Troubleshooting

**Port 8080 already in use:**
```bash
pkill -9 -f "python"
sleep 2
bash ~/soc/scripts/start_dashboard.sh
```

**Tailscale socket not found:**
```bash
pkill tailscaled
rm -f $TMPDIR/tailscaled.sock
bash ~/soc/scripts/start_tailscale.sh
```

**Check all tmux windows:**
```bash
tmux attach -t soc
# Ctrl+B then W to list windows
# Ctrl+B then D to detach
```

---

## Key Design Decisions

| Decision | Reason |
|----------|--------|
| Static HTML instead of Flask | Flask too heavy for 256MB RAM |
| Python http.server | Zero extra dependencies |
| Tailscale 1.32.3 instead of latest | Kernel 4.14 blocks syscalls used by newer versions |
| Userspace-networking mode | /dev/net/tun not available without root |
| bash scripts instead of Python | Minimal memory footprint |
| No database | Flat log files sufficient, lighter on storage |
| No auto-refresh | Manual refresh saves CPU on low-end hardware |

---

## Security concepts demonstrated

- Network monitoring
- Asset discovery
- Device fingerprinting
- Threat detection
- Zero-trust networking (Tailscale / WireGuard)
- Security automation
- SOC sensor architecture
- Secure remote access without port forwarding

---

## Limitations

- Hostname and vendor info not available without root (kernel restricts /proc/net/arp)
- MAC address lookup requires root access
- Tailscale userspace-networking mode has higher latency than TUN mode
- Device runs warm under continuous load — keep ventilated

---

## License

MIT
