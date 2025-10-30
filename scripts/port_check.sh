#!/bin/bash

# Comprehensive Open Port Check Script using nmap and nc

START_TIME_NS=$(date +%s%N)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
PORTS=""
IPV4_TARGET=""
IPV6_TARGET=""
DOMAIN_TARGET=""
VERBOSE=false
RESULTS=()
NC_COMMAND=""

# Function to print usage
print_usage() {
    echo -e "${BLUE}Port Check Script${NC}"
    echo "Usage: $0 [OPTIONS] <target>"
    echo ""
    echo "Options:"
    echo "  -p, --port       Port numbers (comma-separated, e.g., 80,443,3306)"
    echo "  -v, --verbose    Show detailed output from both nmap and nc"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Targets:"
    echo "  IPv4 address     Direct IPv4 target"
    echo "  IPv6 address     Direct IPv6 target"
    echo "  Domain name       Will resolve to both IPv4 and IPv6 automatically"
    echo ""
    echo "Examples:"
    echo "  $0 -p 80,443 example.com"
    echo "  $0 --port 80,443 1.1.1.1"
    echo "  $0 -p 22,80,443 2606:4700:4700::1111"
    echo "  $0 -v -p 80,443 example.com"
}

# Function to check if required tools are installed
check_dependencies() {
    local missing_tools=()
    
    if ! command -v nmap &> /dev/null; then
        missing_tools+=("nmap")
    fi
    
    # Check for OpenBSD-compatible netcat
    if command -v netcat-openbsd &> /dev/null; then
        NC_COMMAND="netcat-openbsd"
    elif command -v nc &> /dev/null; then
        if nc -h 2>&1 | grep -q "OpenBSD"; then
            NC_COMMAND="nc"
        else
            missing_tools+=("netcat-openbsd")
        fi
    else
        missing_tools+=("netcat-openbsd or nc")
    fi
    
    if ! command -v dig &> /dev/null; then
        missing_tools+=("dig")
    fi
    
    if ! command -v bc &> /dev/null; then
        missing_tools+=("bc")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install the missing tools and try again."
        if [[ " ${missing_tools[*]} " =~ " netcat-openbsd " ]]; then
            echo "Note: This script requires the OpenBSD version of netcat."
        fi
        exit 1
    fi
}

# Function to validate IP addresses
validate_ip() {
    local ip=$1
    local version=$2
    
    if [[ $version == "ipv4" ]]; then
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            return 0
        fi
    elif [[ $version == "ipv6" ]]; then
        if [[ $ip =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]] || [[ $ip =~ ^::1$ ]] || [[ $ip =~ ^::ffff: ]]; then
            return 0
        fi
    fi
    return 1
}

# Function to validate domain name
validate_domain() {
    local domain=$1
    
    # Basic domain validation regex
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    fi
    return 1
}

# Function to resolve domain to IP addresses
resolve_domain() {
    local domain=$1
    local ipv4_list=()
    local ipv6_list=()
    
    echo -e "${CYAN}Resolving domain: $domain${NC}"
    
    # Get IPv4 addresses
    local ipv4_results=$(dig +short A "$domain" 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
    if [ -n "$ipv4_results" ]; then
        while IFS= read -r ip; do
            if [ -n "$ip" ]; then
                ipv4_list+=("$ip")
                echo -e "${GREEN}  IPv4: $ip${NC}"
            fi
        done <<< "$ipv4_results"
    fi
    
    # Get IPv6 addresses
    local ipv6_results=$(dig +short AAAA "$domain" 2>/dev/null | grep -E '^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$')
    if [ -n "$ipv6_results" ]; then
        while IFS= read -r ip; do
            if [ -n "$ip" ]; then
                ipv6_list+=("$ip")
                echo -e "${GREEN}  IPv6: $ip${NC}"
            fi
        done <<< "$ipv6_results"
    fi
    
    # Check if we got any results
    if [ ${#ipv4_list[@]} -eq 0 ] && [ ${#ipv6_list[@]} -eq 0 ]; then
        echo -e "${RED}Error: Could not resolve domain $domain to any IP addresses${NC}"
        return 1
    fi
    
    # Update global variables
    if [ ${#ipv4_list[@]} -gt 0 ]; then
        IPV4_TARGET="${ipv4_list[0]}"  # Use first IPv4
        echo -e "${YELLOW}Using IPv4: $IPV4_TARGET${NC}"
    fi
    
    if [ ${#ipv6_list[@]} -gt 0 ]; then
        IPV6_TARGET="${ipv6_list[0]}"  # Use first IPv6
        echo -e "${YELLOW}Using IPv6: $IPV6_TARGET${NC}"
    fi
    
    echo ""
    return 0
}

# Function to validate port numbers
validate_ports() {
    local ports=$1
    local port_list=($(echo "$ports" | tr ',' ' '))
    
    for port in "${port_list[@]}"; do
        # Remove any whitespace
        port=$(echo "$port" | xargs)
        
        # Check if it's a number or range
        if [[ $port =~ ^[0-9]+$ ]]; then
            if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
                return 1
            fi
        elif [[ $port =~ ^[0-9]+-[0-9]+$ ]]; then
            local start_port=$(echo "$port" | cut -d'-' -f1)
            local end_port=$(echo "$port" | cut -d'-' -f2)
            if [ "$start_port" -lt 1 ] || [ "$end_port" -gt 65535 ] || [ "$start_port" -gt "$end_port" ]; then
                return 1
            fi
        else
            return 1
        fi
    done
    return 0
}

# Function to parse command line arguments
parse_arguments() {
    local target=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--port)
                PORTS="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            -*)
                echo -e "${RED}Error: Unknown option $1${NC}"
                print_usage
                exit 1
                ;;
            *)
                if [ -z "$target" ]; then
                    target="$1"
                else
                    echo -e "${RED}Error: Multiple targets provided. Only one target allowed.${NC}"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [ -z "$PORTS" ]; then
        echo -e "${RED}Error: Port numbers are required. Use -p or --port option.${NC}"
        print_usage
        exit 1
    fi
    
    if [ -z "$target" ]; then
        echo -e "${RED}Error: Target is required.${NC}"
        print_usage
        exit 1
    fi
    
    # Validate ports
    if ! validate_ports "$PORTS"; then
        echo -e "${RED}Error: Invalid port format. Please use numbers (1-65535) or ranges (e.g., 80-90)${NC}"
        exit 1
    fi
    
    # Determine target type and set appropriate variables
    if validate_ip "$target" "ipv4"; then
        IPV4_TARGET="$target"
        echo -e "${GREEN}Target: IPv4 $IPV4_TARGET${NC}"
    elif validate_ip "$target" "ipv6"; then
        IPV6_TARGET="$target"
        echo -e "${GREEN}Target: IPv6 $IPV6_TARGET${NC}"
    elif validate_domain "$target"; then
        DOMAIN_TARGET="$target"
        echo -e "${GREEN}Target: Domain $DOMAIN_TARGET${NC}"
        # Resolve domain to IP addresses
        if ! resolve_domain "$target"; then
            exit 1
        fi
    else
        echo -e "${RED}Error: Invalid target format. Please provide a valid IPv4, IPv6, or domain name.${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}Configuration:${NC}"
    echo "  Ports: $PORTS"
    [ -n "$IPV4_TARGET" ] && echo "  IPv4: $IPV4_TARGET"
    [ -n "$IPV6_TARGET" ] && echo "  IPv6: $IPV6_TARGET"
    [ -n "$DOMAIN_TARGET" ] && echo "  Domain: $DOMAIN_TARGET"
    echo ""
}

# Function to run nmap scan (combined TCP and UDP)
run_nmap_scan() {
    local target=$1
    local target_type=$2
    local ports=$3
    
    echo -e "${PURPLE}### nmap combined TCP/UDP scan for $target_type $target ${NC}"
    
    local nmap_cmd="nmap"
    if [[ $target_type == "IPv6" ]]; then
        nmap_cmd="nmap -6"
    fi
    
    # Combined TCP and UDP scan with sudo
    nmap_cmd="sudo $nmap_cmd -sT -sU -Pn --reason -p $ports $target"
    
    echo -e "${YELLOW}Running: $nmap_cmd${NC}"
    echo ""
    
    if [ "$VERBOSE" = true ]; then
        eval "$nmap_cmd"
    else
        eval "$nmap_cmd" 2>/dev/null
    fi
    
    echo ""
}

# Function to run nc scan
run_nc_scan() {
    local target=$1
    local target_type=$2
    local ports=$3
    local protocol=$4
    
    echo -e "${PURPLE}### $NC_COMMAND $protocol ports checking ${NC}"

    local port_list=($(echo "$ports" | tr ',' ' '))
    
    for port in "${port_list[@]}"; do
        port=$(echo "$port" | xargs)
        
        local command_nc_full="$NC_COMMAND -zv"
        if [[ $protocol == "UDP" ]]; then
            command_nc_full="$NC_COMMAND -zvu"
        fi
        command_nc_full="$command_nc_full -w 4 $target $port"
        
        echo -e "${YELLOW}Run: $command_nc_full${NC}"
        $command_nc_full
    done

    echo ""
}

# Function to parse and summarize results
parse_and_summarize() {
    echo -e "${GREEN}## Summary ${NC}"
    echo "Port checking completed for:"
    [ -n "$IPV4_TARGET" ] && echo "  IPv4: $IPV4_TARGET"
    [ -n "$IPV6_TARGET" ] && echo "  IPv6: $IPV6_TARGET"
    [ -n "$DOMAIN_TARGET" ] && echo "  Domain: $DOMAIN_TARGET"
    echo "Ports checked: $PORTS"
    echo ""
    echo -e "${YELLOW}Note: Check the detailed output above for specific port status${NC}"
    echo -e "${YELLOW}Use -v flag for more detailed output from individual tools${NC}"
}

# Main function
main() {
    check_dependencies
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Run scans for IPv4 if provided
    if [ -n "$IPV4_TARGET" ]; then
        echo ""
        echo ""
        echo -e "${GREEN}## Starting scans for IPv4: $IPV4_TARGET ${NC}"
        echo ""
        
        # Combined TCP/UDP nmap scan
        run_nmap_scan "$IPV4_TARGET" "IPv4" "$PORTS"
        
        # Individual TCP and UDP nc scans
        run_nc_scan "$IPV4_TARGET" "IPv4" "$PORTS" "TCP"
        run_nc_scan "$IPV4_TARGET" "IPv4" "$PORTS" "UDP"
    fi
    
    # Run scans for IPv6 if provided
    if [ -n "$IPV6_TARGET" ]; then
        echo ""
        echo -e "${GREEN}## Starting scans for IPv6: $IPV6_TARGET ${NC}"
        echo ""
        
        # Combined TCP/UDP nmap scan
        run_nmap_scan "$IPV6_TARGET" "IPv6" "$PORTS"
        
        # Individual TCP and UDP nc scans
        run_nc_scan "$IPV6_TARGET" "IPv6" "$PORTS" "TCP"
        run_nc_scan "$IPV6_TARGET" "IPv6" "$PORTS" "UDP"
    fi
}

# Run main function
main "$@"

# End time capture and calculate elapsed time (output to stderr)
END_TIME_NS=$(date +%s%N)
ELAPSED_NS=$((END_TIME_NS - START_TIME_NS))
ELAPSED_S_DECIMAL=$(echo "scale=3; $ELAPSED_NS / 1000000000" | bc)
echo "Elapsed time: $ELAPSED_S_DECIMAL seconds." >&2
