#!/bin/bash

# IPTables Management Toolkit
# This script provides a centralized way to manage iptables and ip6tables rules.

# --- Helper Functions ---

# Function to display a separator and a title
_print_header() {
    echo "-----------------------------------------"
    echo "$1"
    echo "-----------------------------------------"
}

# --- Core Functions ---

# Show all rules for a given command (iptables or ip6tables)
show_rules() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: '$cmd' command not found."
        return 1
    fi

    _print_header "FILTER"
    "$cmd" -vL --line-numbers
    _print_header "NAT"
    "$cmd" -vL -t nat --line-numbers
    _print_header "MANGLE"
    "$cmd" -vL -t mangle --line-numbers
    _print_header "RAW"
    "$cmd" -vL -t raw --line-numbers
    _print_header "SECURITY"
    "$cmd" -vL -t security --line-numbers
}

# Show numeric rules for a given command
show_numeric_rules() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: '$cmd' command not found."
        return 1
    fi
    "$cmd" -vL -n --line-numbers
}

# Save rules for a given command
save_rules() {
    local cmd=$1
    local save_cmd=$2
    local rules_file=$3
    local ipt_dir="/etc/iptables"

    if ! command -v "$save_cmd" &> /dev/null; then
        echo "Error: '$save_cmd' command not found."
        return 1
    fi

    if [ ! -d "$ipt_dir" ]; then
        echo "Directory '$ipt_dir' not found. Creating it..."
        mkdir -p "$ipt_dir"
        if [ $? -ne 0 ]; then
            echo "Failed to create directory '$ipt_dir'. Please check permissions."
            return 1
        fi
    fi

    echo "Saving $cmd rules to $rules_file..."
    "$save_cmd" > "$rules_file"
    if [ $? -eq 0 ]; then
        echo "Rules saved successfully."
    else
        echo "Failed to save rules. Please check permissions or run with sudo."
        return 1
    fi
}

# --- Usage and Argument Parsing ---

usage() {
    echo "Usage: $0 {show|shownum|save} [v6]"
    echo
    echo "Commands:"
    echo "  show      List all rules for iptables (or ip6tables if 'v6' is specified)."
    echo "  shownum   List all rules in numeric format for iptables (or ip6tables if 'v6' is specified)."
    echo "  save      Save rules for iptables (or ip6tables if 'v6' is specified)."
    echo "  help      Show this help message."
    echo
    echo "Options:"
    echo "  v6        Use ip6tables instead of iptables."
}

main() {
    if [ "$EUID" -ne 0 ] && [ "$1" == "save" ]; then
      echo "The 'save' command requires root privileges. Please run with sudo."
      exit 1
    fi

    local action=$1
    local version=${2:-"v4"}
    local cmd="iptables"
    local save_cmd="iptables-save"
    local rules_file="/etc/iptables/rules.v4"

    if [ "$version" == "v6" ]; then
        cmd="ip6tables"
        save_cmd="ip6tables-save"
        rules_file="/etc/iptables/rules.v6"
    fi

    case "$action" in
        show)
            show_rules "$cmd"
            ;;
        shownum)
            show_numeric_rules "$cmd"
            ;;
        save)
            save_rules "$cmd" "$save_cmd" "$rules_file"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo "Error: Invalid command '$action'"
            usage
            exit 1
            ;;
    esac
}

# Run the main function with all script arguments
main "$@"
