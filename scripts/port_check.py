#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Check for open TCP/UDP ports on a target host.

Runnable with uv (no external tools needed):
    uv run port_check.py -p 80,443 example.com
    uv run port_check.py --port 80-90 2606:4700:4700::1111

This is a pure-Python stdlib port of port_check.sh / port_check.go.
Note: UDP scanning via connect is unreliable; a timeout does not
definitively mean a port is closed (open UDP ports may not respond).
"""

from __future__ import annotations

import socket
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

DEFAULTS = {"timeout": 2, "workers": 100}


class PortChecker:
    def __init__(self) -> None:
        self.ports: list[tuple[int, int]] = []
        self.target = ""

    def parse_ports(self, port_str: str) -> None:
        for part in port_str.split(","):
            part = part.strip()
            if not part:
                return
            if "-" in part:
                start_s, end_s = part.split("-", 1)
                start, end = int(start_s), int(end_s)
            else:
                start = end = int(part)
            if start < 1 or end > 65535 or start > end:
                sys.exit(f"Error: Invalid port format: {part} (must be 1-65535).")
            self.ports.append((start, end))

    def scan_port(self, ip: str, port: int, proto: str) -> None:
        family = socket.AF_INET6 if ":" in ip else socket.AF_INET
        sock_type = socket.SOCK_STREAM if proto == "tcp" else socket.SOCK_DGRAM
        sock = socket.socket(family, sock_type)
        sock.settimeout(self.timeout)
        try:
            sock.connect((ip, port))
        except OSError:
            return
        finally:
            sock.close()
        print("{:<5} {:<10} Open".format(str(port), proto.upper()))

    def scan_ip(self, ip: str) -> None:
        jobs: list[tuple[str, int, str]] = []
        for start, end in self.ports:
            for port in range(start, end + 1):
                jobs.append((ip, port, "tcp"))
                jobs.append((ip, port, "udp"))
        with ThreadPoolExecutor(max_workers=self.workers) as pool:
            futures = {pool.submit(self.scan_port, *job): job for job in jobs}
            for _ in as_completed(futures):
                pass

    def resolve_target(self) -> list[str]:
        try:
            socket.inet_pton(socket.AF_INET6, self.target)
            return [self.target]
        except OSError:
            pass
        try:
            socket.inet_pton(socket.AF_INET, self.target)
            return [self.target]
        except OSError:
            pass
        try:
            return list(dict.fromkeys(
                info[4][0] for info in socket.getaddrinfo(self.target, None)
            ))
        except socket.gaierror as exc:
            sys.exit(f"Error resolving target {self.target}: {exc}")

    def build_argv(self, argv: list[str]) -> None:
        if len(argv) == 1 or argv[0] in ("-h", "--help"):
            self.usage()
            sys.exit(0)
        if argv[0] in ("-p", "--port"):
            self.parse_ports(argv[1])
            if len(argv) >= 3:
                self.target = argv[2]
        else:
            self.target = argv[0]
            for k, val in enumerate(argv):
                if val in ("-p", "--port") and k + 1 < len(argv):
                    self.parse_ports(argv[k + 1])
        if not self.ports:
            sys.exit("Error: Port numbers are required. Use -p or --port option.")
        if not self.target:
            sys.exit("Error: Target is required.")
        self.timeout = DEFAULTS["timeout"]
        self.workers = DEFAULTS["workers"]

    def usage(self) -> None:
        print(
            """Usage: uv run port_check.py [OPTIONS] <target>

Options:
  -p, --port       Port numbers or ranges (comma-separated, e.g., 80,443,1-1024)
  -h, --help       Show this help message

Targets:
  IPv4 address     Direct IPv4 target
  IPv6 address     Direct IPv6 target
  Domain name      Will resolve to both IPv4 and IPv6 automatically

Examples:
  uv run port_check.py -p 80,443 example.com
  uv run port_check.py --port 80,443 1.1.1.1
  uv run port_check.py -p 22,80,443 2606:4700:4700::1111"""
        )

    def run(self) -> None:
        ips = self.resolve_target()
        if not ips:
            sys.exit(f"Error: Could not resolve target {self.target}.")
        for ip in ips:
            print(f"\n--- Starting scans for {ip} ---")
            self.scan_ip(ip)


def main(argv: list[str]) -> int:
    checker = PortChecker()
    checker.build_argv(argv)
    checker.run()
    return 0


if __name__ == "__main__":
    start = time.time()
    code = main(sys.argv[1:])
    print(f"Elapsed time: {time.time() - start:.3f} seconds.", file=sys.stderr)
    sys.exit(code)
