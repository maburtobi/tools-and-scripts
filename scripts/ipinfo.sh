#!/bin/bash

# Check for required commands
for cmd in curl bc jq; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: Required command '$cmd' is not installed." >&2
    exit 1
  fi
done

# Fetches public IP information from ipinfo.io
# Accepts one or more IP addresses separated by spaces or commas.

# Start time capture
START_TIME_NS=$(date +%s%N)

# Function to display "--help" message
show_help() {
    echo "Usage: ./ipinfo.sh [OPTIONS] <ip1> [ip2,ip3 ...]"
    echo ""
    echo "Fetches public IP information from ipinfo.io for one or more IPs."
    echo ""
    echo "Arguments can be separated by spaces or commas."
    echo ""
    echo "Options:"
    echo "  --help    Show this help message and exit."
    echo ""
    echo "Examples:"
    echo "  ./ipinfo.sh 8.8.8.8"
    echo "  ./ipinfo.sh 8.8.8.8 1.1.1.1"
    echo "  ./ipinfo.sh 8.8.8.8,1.1.1.1"
}

# Check for --help flag or no arguments
if [ "$1" = "--help" ] || [ "$#" -eq 0 ]; then
    show_help
    exit 0
fi

# Process all arguments concurrently and capture the output
output=$(for ip in $(echo "$@" | tr ',' ' '); do
    curl --silent https://ipinfo.io/${ip} &
done
wait)

# Format the concatenated JSON objects into a valid JSON array
json_output=$(echo "$output" | sed 's/}{/},{/g')
echo "[$json_output]" | jq '.[] | {ip, hostname, city, region, org, timezone} + (if has("anycast") then {anycast} else {} end)'

# End time capture and calculate elapsed time (output to stderr)
END_TIME_NS=$(date +%s%N)
ELAPSED_NS=$((END_TIME_NS - START_TIME_NS))
ELAPSED_S_DECIMAL=$(echo "scale=3; $ELAPSED_NS / 1000000000" | bc)
echo "Elapsed time: $ELAPSED_S_DECIMAL seconds." >&2
