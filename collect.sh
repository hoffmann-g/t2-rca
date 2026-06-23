#!/bin/bash
# T2 - Advanced Computer Networks - PUCRS
# Group: Guilherme Hoffmann, Gabriel Ottoneli, João Carvalho, Guilherme Cassol
# Usage: sudo ./collect.sh university | home

CAPTURE_DURATION=2100  # 35 minutes in seconds

# ── Sanity checks ──────────────────────────────────────────

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run with sudo."
    echo "Usage: sudo $0 university | home"
    exit 1
fi

ENVIRONMENT=$1
if [[ "$ENVIRONMENT" != "university" && "$ENVIRONMENT" != "home" ]]; then
    echo "ERROR: Invalid environment. Choose 'university' or 'home'."
    echo "Usage: sudo $0 university | home"
    exit 1
fi

for TOOL in nmap tcpdump; do
    if ! command -v "$TOOL" &>/dev/null; then
        echo "ERROR: '$TOOL' is not installed. Install it and try again."
        exit 1
    fi
done

# ── Setup ──────────────────────────────────────────────────

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$BASE_DIR/$ENVIRONMENT"
mkdir -p "$OUTPUT_DIR"

IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -1)
if [[ -z "$IFACE" ]]; then
    echo "ERROR: No active network interface found."
    exit 1
fi

IP=$(ip addr show "$IFACE" | awk '/inet / {print $2}' | cut -d/ -f1)
CIDR=$(ip addr show "$IFACE" | awk '/inet / {print $2}')
MAC=$(ip link show "$IFACE" | awk '/link\/ether/ {print $2}')
GATEWAY=$(ip route show default | awk '/default/ {print $3}')
NETWORK=$(ip route show dev "$IFACE" | awk '/proto kernel/ {print $1}' | head -1)

echo ""
echo "======================================================"
echo "  Data collection — Environment: $ENVIRONMENT"
echo "======================================================"

# ── Step 1: Machine info ───────────────────────────────────

echo ""
echo "[1/4] Machine identification"
echo "  Hostname  : $(hostname)"
echo "  Interface : $IFACE"
echo "  IP        : $IP"
echo "  MAC       : $MAC"
echo "  Gateway   : $GATEWAY"
echo "  Network   : $NETWORK"

cat > "$OUTPUT_DIR/machine.txt" <<EOF
Environment : $ENVIRONMENT
Hostname    : $(hostname)
Interface   : $IFACE
IP          : $CIDR
MAC         : $MAC
Gateway     : $GATEWAY
Network     : $NETWORK
Timestamp   : $(date '+%Y-%m-%d %H:%M:%S')
EOF

echo "  Saved → $OUTPUT_DIR/machine.txt"

# ── Step 2: Traffic capture ────────────────────────────────

echo ""
echo "[2/4] Starting traffic capture ($((CAPTURE_DURATION / 60)) minutes)..."

PCAP="$OUTPUT_DIR/${ENVIRONMENT}_capture.pcap"
tcpdump -i "$IFACE" -w "$PCAP" &
TCPDUMP_PID=$!

echo "  PID    : $TCPDUMP_PID"
echo "  Output : $PCAP"

# ── Step 3: Nmap ───────────────────────────────────────────

echo ""
echo "[3/4] Nmap — host discovery on $NETWORK ..."

NMAP_HOSTS="$OUTPUT_DIR/nmap_hosts.txt"
NMAP_HOSTS_XML="$OUTPUT_DIR/nmap_hosts.xml"
NMAP_SERVICES="$OUTPUT_DIR/nmap_services.txt"
NMAP_SERVICES_XML="$OUTPUT_DIR/nmap_services.xml"

nmap -sn "$NETWORK" -oN "$NMAP_HOSTS" -oX "$NMAP_HOSTS_XML"

ACTIVE_HOSTS=$(grep -c "Host is up" "$NMAP_HOSTS" 2>/dev/null || echo 0)
echo "  Active hosts found: $ACTIVE_HOSTS"

HOSTS_LIST=$(grep "Nmap scan report" "$NMAP_HOSTS" | awk '{print $5}')
if [[ -n "$HOSTS_LIST" ]]; then
    echo "  Running service/OS detection in background..."
    echo "$HOSTS_LIST" | xargs nmap -sV -O --osscan-guess -T4 --open \
        -oN "$NMAP_SERVICES" -oX "$NMAP_SERVICES_XML" &
    NMAP_PID=$!
    echo "  PID    : $NMAP_PID"
    echo "  Output : $NMAP_SERVICES"
else
    NMAP_PID=""
    echo "  WARNING: No hosts found to scan for services."
fi

# ── Step 4: nProbe + ntopng instructions ──────────────────

echo ""
echo "[4/4] nProbe + ntopng — open two more terminals and run:"
echo ""
echo "  ┌─ Terminal 2 (nProbe) ─────────────────────────────────────────"
echo "  │  sudo nprobe --interface $IFACE --ntopng zmq://127.0.0.1:5556 -b 0"
echo "  └───────────────────────────────────────────────────────────────"
echo ""
echo "  ┌─ Terminal 3 (ntopng) ─────────────────────────────────────────"
echo "  │  sudo ntopng -i zmq://127.0.0.1:5556 -d $OUTPUT_DIR/ntopng_data"
echo "  └───────────────────────────────────────────────────────────────"
echo ""
echo "  Web interface → http://localhost:3000  (admin / admin)"

# Save PIDs
{
    echo "tcpdump=$TCPDUMP_PID"
    [[ -n "$NMAP_PID" ]] && echo "nmap=$NMAP_PID"
} > "$OUTPUT_DIR/pids.txt"

# ── Countdown ─────────────────────────────────────────────

echo ""
echo "======================================================"
echo "  Capturing traffic — do NOT close this terminal."
echo "  Take ntopng screenshots while you wait."
echo "======================================================"

REMAINING=$CAPTURE_DURATION
while [[ $REMAINING -gt 0 ]]; do
    MINS=$(( REMAINING / 60 ))
    SECS=$(( REMAINING % 60 ))
    printf "\r  Time remaining: %02d:%02d " "$MINS" "$SECS"
    sleep 1
    REMAINING=$(( REMAINING - 1 ))
    # Stop if tcpdump died unexpectedly
    if ! kill -0 "$TCPDUMP_PID" 2>/dev/null; then
        echo ""
        echo "  tcpdump stopped early."
        break
    fi
done

# Stop tcpdump cleanly
kill "$TCPDUMP_PID" 2>/dev/null
wait "$TCPDUMP_PID" 2>/dev/null

echo ""
echo ""
echo "======================================================"
echo "  Capture complete!"
echo "  File : $PCAP"
[[ -n "$NMAP_PID" ]] && echo "  Nmap may still be running (PID $NMAP_PID)."
echo "  All results saved to: $OUTPUT_DIR"
echo "======================================================"
