#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests>=2.31",
# ]
# ///
"""Fetches public IP information from ipinfo.io for one or more IPs.

Runnable with uv (auto-provisions Python + dependencies):
    uv run ipinfo.py 8.8.8.8
    uv run ipinfo.py 8.8.8.8,1.1.1.1

Accepts one or more IP addresses separated by spaces or commas.
"""

from __future__ import annotations

import json
import sys
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

FIELDS = ("ip", "hostname", "city", "region", "country", "org", "timezone")
URL = "https://ipinfo.io/{}"


def show_help() -> None:
    print(
        """Usage: uv run ipinfo.py [OPTIONS] <ip1> [ip2,ip3 ...]

Fetches public IP information from ipinfo.io for one or more IPs.

Arguments can be separated by spaces or commas.

Options:
  --help    Show this help message and exit.

Examples:
  uv run ipinfo.py 8.8.8.8
  uv run ipinfo.py 8.8.8.8 1.1.1.1
  uv run ipinfo.py 8.8.8.8,1.1.1.1"""
    )


def fetch(ip: str) -> dict:
    resp = requests.get(URL.format(ip), timeout=10)
    resp.raise_for_status()
    return resp.json()


def main(argv: list[str]) -> int:
    if not argv or argv[0] == "--help":
        show_help()
        return 0

    ips = [a.strip() for arg in argv for a in arg.split(",") if a.strip()]
    if not ips:
        show_help()
        return 1

    results: list[dict] = []
    with ThreadPoolExecutor(max_workers=min(len(ips), 32)) as pool:
        futures = {pool.submit(fetch, ip): ip for ip in ips}
        for future in as_completed(futures):
            try:
                results.append(future.result())
            except requests.RequestException as exc:
                print(f"Error fetching {futures[future]}: {exc}", file=sys.stderr)
                return 1

    print(json.dumps([{f: r.get(f) for f in FIELDS} for r in results], indent=2))

    summary = Counter(r.get("country") for r in results if r.get("country"))
    print("\nCountry Summary:")
    for country, count in sorted(summary.items()):
        print(f"{country}: {count}")

    return 0


if __name__ == "__main__":
    start = time.time()
    code = main(sys.argv[1:])
    print(f"Elapsed time: {time.time() - start:.3f} seconds.", file=sys.stderr)
    sys.exit(code)
