BlackICE

BlackICE is a host hardening utility for Linux systems that locks down your network stack with ultra-hardened UFW configurations — while still allowing safe web browsing (HTTPS, DNS, NTP, DHCP).

Overview

BlackICE is designed for users who want a near-impenetrable local firewall without losing essential online functionality. It configures UFW (Uncomplicated Firewall) with a restrictive “deny-all” policy, then selectively allows minimal outbound traffic required for browsing, while fully disabling all inbound connections.

This script also applies deep kernel-level hardening (via sysctl) to block redirects, source routing, TCP fingerprinting, and other network-layer vectors often used in exploitation.

Features

- Inbound traffic: completely blocked by default.  
- Outbound traffic: limited to HTTPS, encrypted DNS, NTP, DHCP.  
- Encrypted DNS enforcement (DoT/DoH) with optional plaintext fallback.  
- Kernel hardening: disables source routing, redirects, ICMP abuse, TCP timestamps, and SACK.
- Verbose logging: ufw logging high for maximum visibility.
- Auto-detection of DNS resolvers from /etc/resolv.conf
- Safe defaults: browser functionality intact, minimal exposure footprint.  
- No dependencies: uses only built-in Linux tools (bash, ufw, sysctl).

Usage

1. Clone or download the script: git clone https://github.com/Gainer552/BlackICE.git

2. chmod +x blackice.sh

3. Run it with root privileges: sudo ./blackice.sh

4. (Optional) Dry-run mode — preview actions without applying changes: sudo DRY_RUN=true ./blackice.sh

5. Verify firewall status: sudo ufw status verbose

Configuration Variables

Inside the script, you can adjust:

| Variable | Description | Default |
|-----------|-------------|----------|
| `ALLOW_HTTP` | Allow HTTP (port 80) traffic | `false` |
| `ALLOW_PLAINTEXT_DNS` | Allow normal DNS (UDP/TCP 53) instead of encrypted DNS | `false` |
| `DRY_RUN` | Simulate changes without applying | `false` |

> By default, BlackICE allows only HTTPS, DoT/DoH, NTP, and DHCP — this provides full web functionality while minimizing exposure.

Example Behavior

After installation:

- All inbound packets are dropped.  
- Only essential outbound traffic leaves your machine.  
- DNS lookups are encrypted (if supported).  
- Logs record every blocked attempt at /var/log/ufw.log.  
- Browsing works (HTTPS + DNS), but background telemetry and most services are firewalled off.

Reverting Changes

If something breaks or you need to undo the changes:

- sudo ufw --force reset
- sudo rm /etc/sysctl.d/99-ultra-harden.conf
- sudo sysctl --system

Legal Disclaimer

BlackICE is provided as-is for educational and defensive cybersecurity purposes.  
The authors and contributors make no warranties about its performance, suitability, or fitness for any purpose.  
Use at your own risk.

You are solely responsible for ensuring that the configuration complies with your organization’s security policies, network requirements, and applicable laws.  
Do not deploy or modify this script on systems you do not own or have explicit authorization to administer.
