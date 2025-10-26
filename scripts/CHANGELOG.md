# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-10-26

### Added
- **`port_check.sh`**: A comprehensive script to check for open ports on a target using `nmap` and `netat-openbsd`. It supports IPv4, IPv6, and domain targets.
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