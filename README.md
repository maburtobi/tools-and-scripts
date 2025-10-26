# tools-and-scripts
Automate and shorten the engineering time

## ipinfo.sh

Fetches public IP information from ipinfo.io for one or more IPs.

**Prequisites:**
- curl
- bc

**Changes in 1.1.0:**
- Added a check to ensure required commands (`curl`, `bc`) are installed before execution.

**Usage:**
```sh
Usage: ./ipinfo.sh [OPTIONS] <ip1> [ip2,ip3 ...]

Fetches public IP information from ipinfo.io for one or more IPs.

Arguments can be separated by spaces or commas.

Options:
  --help    Show this help message and exit.

Examples:
  ./ipinfo.sh 8.8.8.8
  ./ipinfo.sh 8.8.8.8 1.1.1.1
  ./ipinfo.sh 8.8.8.8,1.1.1.1
```

---

## port_check.sh

A comprehensive script to check for open TCP and UDP ports on a target host. It uses `nmap` for powerful scanning and `nc` (netcat-openbsd) for quick, individual port checks. The script can check both IPv4, IPv6 addresses, or using a domain name.

**Prequisites:**
- nmap
- dig
- netcat (OpenBSD variant)

**Usage:**
```sh
Usage: ./port_check.sh [OPTIONS] <target>

Options:
  -p, --port       Port numbers (comma-separated, e.g., 80,443,3306)
  -v, --verbose    Show detailed output from both nmap and nc
  -h, --help       Show this help message

Targets:
  IPv4 address     Direct IPv4 target
  IPv6 address     Direct IPv6 target
  Domain name       Will resolve to both IPv4 and IPv6 automatically

Examples:
  ./port_check.sh -p 80,443 example.com
  ./port_check.sh --port 80,443 1.1.1.1
  ./port_check.sh -p 22,80,443 2606:4700:4700::1111
  ./port_check.sh -v -p 80,443 example.com
```