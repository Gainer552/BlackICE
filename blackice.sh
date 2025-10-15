#!/bin/bash

# Display UFW configs.

echo "Displaying current UFW configurations..."
sleep 5s
echo
sudo ufw status verbose
sleep 15s
echo

# Harden UFW configs.
echo "Hardening UFW configurations..."
sleep 15s
echo


# Ultra-hardened UFW setup (auto-detects DNS resolvers)
set -euo pipefail

ALLOW_HTTP=false          # true to permit port 80 outbound
ALLOW_PLAINTEXT_DNS=false # if false, prefer DoT/DoH only
DRY_RUN=false             # true = preview only

run(){ [ "$DRY_RUN" = true ] && echo "[DRY] $*" || eval "$*"; }

[ "$(id -u)" -eq 0 ] || { echo "Run as root"; exit 1; }
command -v ufw >/dev/null || { echo "Install ufw first"; exit 2; }

# --- Detect resolvers from resolv.conf ---
DNS_RESOLVERS=$(grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
[ -z "$DNS_RESOLVERS" ] && DNS_RESOLVERS="1.1.1.1,9.9.9.9"
echo "[+] Using DNS resolvers: $DNS_RESOLVERS"

# --- Firewall reset & defaults ---
run ufw --force reset
run ufw default deny incoming
run ufw default deny outgoing
run ufw default deny routed
run ufw allow in on lo
run ufw allow out on lo

# --- Essential outbound rules ---
run ufw allow out 68/udp comment 'DHCP client'
run ufw allow out 123/udp comment 'NTP sync'

# --- DNS rules ---
IFS=',' read -r -a resolvers <<<"$DNS_RESOLVERS"
for r in "${resolvers[@]}"; do
  if [ "$ALLOW_PLAINTEXT_DNS" = true ]; then
    run ufw allow out to "$r" port 53 proto udp comment 'DNS UDP'
    run ufw allow out to "$r" port 53 proto tcp comment 'DNS TCP'
  else
    run ufw allow out to "$r" port 853 proto tcp comment 'DoT'
    run ufw allow out to "$r" port 443 proto tcp comment 'DoH'
  fi
done

# --- Web browsing ---
$ALLOW_HTTP && run ufw allow out 80/tcp comment 'HTTP out'
run ufw allow out 443/tcp comment 'HTTPS out'

# --- Logging & enable ---
run ufw logging high
run ufw --force enable

# --- Kernel hardening baseline ---
cat >/etc/sysctl.d/99-ultra-harden.conf <<'EOF'
# Core network stack hardening
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_sack=0
net.ipv4.tcp_fin_timeout=15
net.ipv4.ip_forward=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0
EOF
run sysctl --system >/dev/null 2>&1 || true

run ufw status verbose
echo
echo "✅ UFW hardened and enabled."
echo "   Allowed outbound: HTTPS, DNS(DoT/DoH), NTP, DHCP"
echo "   All inbound traffic blocked."
echo "   Log file: /var/log/ufw.log"