#!/bin/bash
set -e

# Enable debug output if DEBUG=1
[ "$DEBUG" = "1" ] && set -x

# Defaults
: "${WORKERS:=1}"
: "${PORT:=8443}"

# Determine external and internal IP
EXTERNAL_IP=$(curl -s -4 https://api.ipify.org || curl -s -4 https://ifconfig.me)
INTERNAL_IP=$(ip -4 route get 8.8.8.8 | awk '/src/ {print $7; exit}')

if [ -z "$EXTERNAL_IP" ]; then
  echo "[F] Cannot determine external IP address."
  exit 3
fi

if [ -z "$INTERNAL_IP" ]; then
  echo "[F] Cannot determine internal IP address."
  exit 4
fi

# Generate or use existing secret
if [ "$SECRET" = "auto" ] || [ -z "$SECRET" ]; then
  SECRET=$(head -c 16 /dev/urandom | xxd -ps)
  echo "[+] Generated secret: $SECRET"
fi

# Print connection info
echo "======================================"
echo "MTProto proxy starting"
echo "[*] External IP: $EXTERNAL_IP"
echo "[*] Internal IP: $INTERNAL_IP"
echo "[*] Port: $PORT"
echo "[*] Workers: $WORKERS"
echo
echo "Use this secret to connect to your proxy:"
echo "tg://proxy?server=${EXTERNAL_IP}&port=${PORT}&secret=${SECRET}"
echo "https://t.me/proxy?server=${EXTERNAL_IP}&port=${PORT}&secret=${SECRET}"
echo "======================================"

# Start proxy
exec /usr/local/bin/mtproto-proxy \
    -u mtproxy \
    -p 8888 \
    -H "$PORT" \
    -S "$SECRET" \
    --aes-pwd /etc/mtproto-proxy/proxy-secret \
    /etc/mtproto-proxy/proxy-multi.conf \
    -M "$WORKERS" \
    --allow-skip-dh \
    --nat-info "$INTERNAL_IP:$EXTERNAL_IP"
