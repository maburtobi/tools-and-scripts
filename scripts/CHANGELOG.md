# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.1] - 2025-10-30

### Added
- **`port_check.sh` to `port_check.go`**: The port checking script has been completely rewritten in Go. It is now a self-contained executable with no external dependencies.

## [1.2.0] - 2025-10-28

### Added
- **`port_check.sh`**: Added a dependency check for `bc`.

### Changed
- **`ipt.sh`**: Refactored the script into a single, powerful toolkit. Instead of creating multiple files, it now accepts arguments (`show`, `shownum`, `save`) and an optional `v6` flag to manage `iptables` and `ip6tables` rules efficiently. The new script is more readable, maintainable, and includes a help guide.

## [1.1.0] - 2025-10-26

### Added
- **`port_check.sh`**: A comprehensive script to check for open ports on a target using `nmap` and `netcat-openbsd`. It supports IPv4, IPv6, and domain targets.
- **`ipinfo.sh`**: Added a dependency check to ensure `curl` and `bc` are installed before running.

### Changed
- **`port_check.sh`**: The script now specifically requires the OpenBSD variant of `netcat`. It verifies the `nc` version using `nc -h` to ensure compatibility.

## [1.0.0] - 2025-10-19

### Added
- Fetches information for multiple IPs concurrently to improve performance.
- Outputs a valid JSON array for easy parsing by other tools.
- Measures and displays the total execution time to standard error.

### Changed
- The script now displays elapsed time in seconds with millisecond precision (e.g., "1.504 seconds").

### Fixed
- Improved script portability for POSIX-compliant shells (like `dash` on Debian) by replacing non-standard `[[` with `[`.