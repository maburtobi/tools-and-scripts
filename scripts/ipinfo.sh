#!/bin/bash

# Fetches public IP information from ipinfo.io
# Accepts one or more IP addresses separated by spaces or commas.

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
if [[ "$1" == "--help" || "$#" -eq 0 ]]; then
    show_help
    exit 0
fi

# Process all arguments, replacing any commas with spaces
for ip in $(echo "$@" | tr ',' ' '); do
    curl --silent https://ipinfo.io/${ip}
done
