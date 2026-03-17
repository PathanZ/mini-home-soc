#!/data/data/com.termux/files/usr/bin/bash

LOG_DIR="$HOME/soc/logs"
PROFILE_DIR="$HOME/soc/profiles"
REPORT_DIR="$HOME/soc/reports"
WWW_DIR="$HOME/soc/www"

mkdir -p "$WWW_DIR"

OUT="$WWW_DIR/index.html"
GENERATED="$(date '+%Y-%m-%d %H:%M:%S')"

# ── Read data ─────────────────────────────────────────────
CURRENT_DEVICES=""
KNOWN_COUNT=0
CURRENT_COUNT=0

[ -f "$LOG_DIR/current_devices.txt" ] && {
  CURRENT_DEVICES=$(cat "$LOG_DIR/current_devices.txt")
  CURRENT_COUNT=$(wc -l < "$LOG_DIR/current_devices.txt")
}
[ -f "$LOG_DIR/known_devices.txt" ] && \
  KNOWN_COUNT=$(wc -l < "$LOG_DIR/known_devices.txt")

NEW_COUNT=0
[ -f "$LOG_DIR/device_alerts.log" ] && \
  NEW_COUNT=$(grep -c "NEW DEVICE" "$LOG_DIR/device_alerts.log" 2>/dev/null || echo 0)

ALERT_LINES=""
[ -f "$LOG_DIR/device_alerts.log" ] && \
  ALERT_LINES=$(tail -n 30 "$LOG_DIR/device_alerts.log")

SCAN_LINES=""
[ -f "$LOG_DIR/scan_activity.log" ] && \
  SCAN_LINES=$(tail -n 60 "$LOG_DIR/scan_activity.log")

REPORT_LINES=""
LATEST_REPORT=$(ls -t "$REPORT_DIR"/hourly_report_*.txt 2>/dev/null | head -n 1)
[ -n "$LATEST_REPORT" ] && REPORT_LINES=$(cat "$LATEST_REPORT")

# ── Build device rows ─────────────────────────────────────
DEVICE_ROWS=""
if [ -n "$CURRENT_DEVICES" ]; then
  while IFS= read -r ip; do
    [ -z "$ip" ] && continue

    if grep -qx "$ip" "$LOG_DIR/known_devices.txt" 2>/dev/null; then
      cls="known"
    else
      cls="new"
    fi

    PROFILE_FILE=$(ls -t "$PROFILE_DIR/${ip}_"*.txt 2>/dev/null | head -n 1)
    ports="—"
    first_seen="—"

    if [ -n "$PROFILE_FILE" ]; then
      p=$(grep "^[0-9]" "$PROFILE_FILE" | grep "open" | awk '{print $1}' | tr '\n' ' ')
      [ -n "$p" ] && ports="$p" || ports="no open ports"
      first_seen=$(grep "^Generated:" "$PROFILE_FILE" | cut -d' ' -f2-)
    fi

    if [ "$cls" = "new" ]; then
      badge='<span class="badge bn">NEW</span>'
      dot="dot-new"
      row_class="row-new"
    else
      badge='<span class="badge bk">known</span>'
      dot="dot-ok"
      row_class="row-known"
    fi

    DEVICE_ROWS="$DEVICE_ROWS
    <tr class=\"$row_class\">
      <td><span class=\"dot $dot\"></span></td>
      <td class=\"mono bold\">$ip</td>
      <td class=\"muted\">restricted</td>
      <td class=\"muted\">restricted</td>
      <td class=\"mono portcell\">$ports</td>
      <td class=\"muted small\">$first_seen</td>
      <td>$badge</td>
    </tr>"
  done <<EOF
$CURRENT_DEVICES
EOF
else
  DEVICE_ROWS='<tr><td colspan="7" class="empty">no devices found yet</td></tr>'
fi

# ── Build alert rows ──────────────────────────────────────
ALERT_ROWS=""
if [ -n "$ALERT_LINES" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    escaped=$(printf '%s' "$line" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')
    if echo "$line" | grep -q "NEW DEVICE"; then
      ALERT_ROWS="$ALERT_ROWS<tr class=\"row-new\"><td class=\"wi\">!</td><td class=\"mono\">$escaped</td></tr>"
    else
      ALERT_ROWS="$ALERT_ROWS<tr><td></td><td class=\"mono\">$escaped</td></tr>"
    fi
  done <<EOF
$ALERT_LINES
EOF
else
  ALERT_ROWS='<tr><td colspan="2" class="empty">no alerts yet</td></tr>'
fi

# ── Escape pre blocks ─────────────────────────────────────
SCAN_HTML=$(printf '%s' "$SCAN_LINES" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')
[ -z "$SCAN_HTML" ] && SCAN_HTML="no scan data yet"

REPORT_HTML=$(printf '%s' "$REPORT_LINES" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')
[ -z "$REPORT_HTML" ] && REPORT_HTML="no report generated yet"

# ── Write HTML ────────────────────────────────────────────
cat > "$OUT" <<HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Home SOC</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:monospace;font-size:15px;background:#0d0d0d;color:#c8c8c0;padding:20px;max-width:1400px;margin:0 auto}
h1{font-size:18px;font-weight:normal;letter-spacing:.1em;color:#e8e8e0;margin-bottom:6px}
.sub{font-size:13px;color:#555;margin-bottom:20px;display:flex;align-items:center;gap:12px;flex-wrap:wrap}
.rfbtn{font-size:12px;padding:4px 14px;background:#1a1a1a;border:1px solid #2a2a2a;color:#777;cursor:pointer;font-family:monospace;text-decoration:none}
.stats{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:24px}
.stat{background:#1a1a1a;border:1px solid #2a2a2a;padding:16px 20px}
.stat-lbl{font-size:11px;color:#555;letter-spacing:.08em;text-transform:uppercase;margin-bottom:6px}
.stat-val{font-size:32px;color:#e8e8e0;line-height:1}
.ok{color:#1D9E75}
.warn{color:#BA7517}
section{margin-bottom:28px}
.sec-title{font-size:11px;letter-spacing:.1em;text-transform:uppercase;color:#555;border-bottom:1px solid #1e1e1e;padding-bottom:8px;margin-bottom:12px}
.table-wrap{overflow-x:auto;-webkit-overflow-scrolling:touch}
table{width:100%;border-collapse:collapse;min-width:500px}
td,th{padding:10px 12px;text-align:left;border-bottom:1px solid #1a1a1a;vertical-align:middle;font-size:14px}
th{font-size:11px;color:#555;font-weight:normal;letter-spacing:.06em;padding:8px 12px}
tr.row-new td{background:#1a1200}
tr.row-known:hover td{background:#141414}
.dot{display:inline-block;width:8px;height:8px;border-radius:50%;vertical-align:middle}
.dot-ok{background:#1D9E75}
.dot-new{background:#BA7517}
.badge{font-size:11px;padding:2px 10px;border-radius:2px;display:inline-block}
.bk{background:#0a2a1e;color:#1D9E75;border:1px solid #0f3d2a}
.bn{background:#2a1a00;color:#BA7517;border:1px solid #3d2800}
.wi{color:#BA7517;font-weight:bold;font-size:16px;width:20px}
.mono{font-family:monospace}
.bold{font-weight:bold;color:#e8e8e0}
.muted{color:#555;font-size:13px}
.small{font-size:12px}
.portcell{font-size:12px;color:#9a9a90;max-width:220px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
pre{background:#111;border:1px solid #1e1e1e;padding:16px;font-size:13px;line-height:1.7;white-space:pre-wrap;word-break:break-all;overflow-x:auto}
.empty{color:#444;font-style:italic;padding:12px}
footer{margin-top:20px;font-size:12px;color:#333;border-top:1px solid #1a1a1a;padding-top:12px}
@media(max-width:600px){
  body{padding:12px;font-size:13px}
  h1{font-size:15px}
  .stat-val{font-size:24px}
  .stat{padding:12px 14px}
  td,th{padding:7px 8px;font-size:12px}
  pre{font-size:11px;padding:10px}
}
</style>
</head>
<body>

<h1>&#9632; HOME SOC &mdash; SENSOR NODE</h1>
<div class="sub">
  <span>generated: $GENERATED</span>
  <a href="index.html" class="rfbtn">&#8635; refresh</a>
</div>

<div class="stats">
  <div class="stat"><div class="stat-lbl">active</div><div class="stat-val ok">$CURRENT_COUNT</div></div>
  <div class="stat"><div class="stat-lbl">known</div><div class="stat-val">$KNOWN_COUNT</div></div>
  <div class="stat"><div class="stat-lbl">new alerts</div><div class="stat-val warn">$NEW_COUNT</div></div>
</div>

<section>
<div class="sec-title">active devices</div>
<div class="table-wrap">
<table>
<thead><tr>
  <th style="width:20px"></th>
  <th>IP</th>
  <th>hostname</th>
  <th>vendor</th>
  <th>open ports</th>
  <th>first seen</th>
  <th>status</th>
</tr></thead>
<tbody>
$DEVICE_ROWS
</tbody>
</table>
</div>
</section>

<section>
<div class="sec-title">new device alerts</div>
<div class="table-wrap">
<table><tbody>
$ALERT_ROWS
</tbody></table>
</div>
</section>

<section>
<div class="sec-title">latest port scan</div>
<pre>$SCAN_HTML</pre>
</section>

<section>
<div class="sec-title">hourly report</div>
<pre>$REPORT_HTML</pre>
</section>

<footer>home-soc &nbsp;|&nbsp; read-only &nbsp;|&nbsp; tailscale access only</footer>

</body>
</html>
HTMLEOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dashboard written to $OUT"
