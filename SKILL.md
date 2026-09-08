---
name: tools-and-scripts
description: How to use the networking utilities in this repo (ipinfo and port_check). Use when asked to look up IP/ASN information from ipinfo.io, or to check open ports on an IP, IPv6, or domain. Provides uv run invocations that need no preinstalled tools.
---

# SKILL.md — tools-and-scripts

Guidance for AI agents using the network tools in this repository.

## Repo purpose

`tools-and-scripts` is a small collection of networking utilities. Each tool has
multiple implementations: a shell script (`scripts/*.sh`), and most have a
`uv`-runnable Python version (`scripts/*.py`) and/or a standalone Go program
(`scripts/*.go`).

## Source of truth

- Per-tool usage lives in `README.md`.
- Change history lives in `scripts/CHANGELOG.md` (Keep a Changelog / Conventional Commits).
- Scripts live in `scripts/`.

## Tool catalog

| Tool | What it does | Fastest way to run |
|------|--------------|--------------------|
| `ipinfo` | Fetch public IP info (hostname, city, country, org) from ipinfo.io for one/many IPs + country summary | `uv run scripts/ipinfo.py 8.8.8.8,1.1.1.1` |
| `port_check` | Scan a target for open TCP/UDP ports (IPv4, IPv6, or domain; ports as lists/ranges) | `uv run scripts/port_check.py -p 80,443 example.com` |

### ipinfo

- `scripts/ipinfo.sh` — Bash; requires `curl`, `bc`, `jq`.
- `scripts/ipinfo.py` — `uv`-managed Python; requires `requests` (auto-installed). **Preferred.**

### port_check

- `scripts/port_check.sh` — Bash; requires `nmap`, `dig`, OpenBSD/BSD `nc`, `bc`. TCP-only.
- `scripts/port_check.go` — self-contained Go; build with `go build`, run with `go run`.
- `scripts/port_check.py` — pure stdlib Python. **Preferred for agents, no dependencies.**

## Recommendations for agents

Prefer the `uv` Python implementations (`uv run scripts/*.py`):

1. No `nmap`/`netcat`/`jq`/`bc` prerequisites to install on the host.
2. `uv` auto-provisions the interpreter and pinned dependencies from the inline
   `/// script ///` metadata at the top of each file.
3. Uniform invocation pattern and clear `--help` output.

Run everything from the `tools-and-scripts` directory:

```sh
uv run scripts/ipinfo.py 8.8.8.8
uv run scripts/port_check.py -p 80,443 example.com
```

## Platform notes

- **macOS**: the built-in `/usr/bin/nc` is OpenBSD-compatible and accepted by
  `port_check.sh`; `nmap` and the OpenBSD netcat are not installed by default.
  The `.py` implementations avoid these entirely.
- **Sandboxed shells**: `uv` needs to write its cache. If `uv run` fails with
  `Operation not permitted` on a cache lock file (`.git` in the cache dir), the
  shell is running in a sandbox — run `uv run` from a normal terminal instead.

## Conventions

- New features/versions: update `README.md` usage + add a `CHANGELOG.md` entry.
- Keep header/usage text in each script consistent with the README so `--help`
  and docs never drift.
