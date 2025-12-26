# tools-and-scripts
Automate and shorten the engineering time

## ipinfo.sh

Fetches public IP information from ipinfo.io for one or more IPs. The output includes a JSON object for each IP with details like hostname, city, region, country, and more. At the end, it provides a summary of the countries found.

**Prequisites:**
- curl
- bc
- jq

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

**Output:**
```json
[
  {
    "ip": "8.8.8.8",
    "hostname": "dns.google",
    "city": "Mountain View",
    "region": "California",
    "country": "US",
    "org": "AS15169 Google LLC",
    "timezone": "America/Los_Angeles"
  },
  {
    "ip": "1.1.1.1",
    "hostname": "one.one.one.one",
    "city": "South Brisbane",
    "region": "Queensland",
    "country": "AU",
    "org": "AS13335 Cloudflare, Inc.",
    "timezone": "Australia/Brisbane",
    "anycast": true
  }
]

Country Summary:
AU: 1
US: 1
```

---

## port_check

A tool to check for open TCP and UDP ports on a target host. Available as a shell script or a self-contained Go program.

### port_check.sh

A comprehensive script that uses `nmap` and `nc` (netcat-openbsd) for scanning.

**Prequisites:**
- nmap
- dig
- netcat (OpenBSD variant)
- bc

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
  Domain name      Will resolve to both IPv4 and IPv6 automatically

Examples:
  ./port_check.sh -p 80,443 example.com
  ./port_check.sh --port 80,443 1.1.1.1
  ./port_check.sh -p 22,80,443 2606:4700:4700::1111
```

### port_check.go

A self-contained Go program with no external dependencies.

**Prequisites:**
- Go (for building or running from source)

**Usage:**

You can run the program directly using `go run` or build a compiled executable.

**1. Run directly:**
```sh
go run ./port_check.go [OPTIONS] <target>
```

**2. Build the executable:**
You can easily compile binaries for other operating systems from any machine with Go installed. This assume to run from the 'tools-and-scripts/scripts' directory.

```sh
# For Windows
go build -ldflags="-s -w" -o port_check.exe ./port_check.go

# For Linux
GOOS=linux GOARCH=amd64 go build -o port_check ./port_check.go

# For macOS (Apple Silicon)
GOOS=darwin GOARCH=arm64 go build -o port_check ./port_check.go
```

Then run the compiled executable:
```sh
# Windows
./port_check.exe [OPTIONS] <target>
# Linux or MacOS
./port_check [OPTIONS] <target>
```

**Options:**
```
  -p, --port       Port numbers (comma-separated, e.g., 80,443,3306)
  -h, --help       Show this help message
```

**Examples:**
```sh
go run ./port_check.go -p 80,443 example.com
./port_check.exe -p 80,443 1.1.1.1
```

---

## ipt.sh

A script to simplify viewing and managing `iptables` and `ip6tables` rules.

**Prequisites:**
- iptables
- ip6tables

**Usage:**
```sh
Usage: ./ipt.sh {show|shownum|save} [v6]

Commands:
  show      List all rules for iptables (or ip6tables if 'v6' is specified).
  shownum   List all rules in numeric format for iptables (or ip6tables if 'v6' is specified).
  save      Save rules for iptables (or ip6tables if 'v6' is specified).
  help      Show this help message.

Options:
  v6        Use ip6tables instead of iptables.
```
