package main

import (
	"context"
	"flag"
	"fmt"
	"net"
	"os"
	"strings"
	"sync"
	"time"
)

func main() {
	startTime := time.Now()

	// Define command-line flags
	ports := flag.String("p", "", "Port numbers (comma-separated, e.g., 80,443,3306)")
	help := flag.Bool("h", false, "Show this help message")

	flag.Parse()

	if *help || len(os.Args) == 1 {
		printUsage()
		os.Exit(0)
	}

	if *ports == "" {
		fmt.Println("Error: Port numbers are required. Use -p or --port option.")
		printUsage()
		os.Exit(1)
	}

	target := flag.Arg(0)
	if target == "" {
		fmt.Println("Error: Target is required.")
		printUsage()
		os.Exit(1)
	}

	fmt.Printf("Target: %s\n", target)
	fmt.Printf("Ports: %s\n", *ports)

	// Resolve target and get IPs
	ipAddrs, err := resolveTarget(target)
	if err != nil {
		fmt.Printf("Error resolving target: %v\n", err)
		os.Exit(1)
	}

	// Separate IPs into IPv4 and IPv6 lists
	var ipv4Targets, ipv6Targets []net.IP
	for _, ip := range ipAddrs {
		if ip.To4() != nil {
			ipv4Targets = append(ipv4Targets, ip)
		} else {
			ipv6Targets = append(ipv6Targets, ip)
		}
	}

	// Parse ports
	portsToScan, err := parsePorts(*ports)
	if err != nil {
		fmt.Printf("Error parsing ports: %v\n", err)
		os.Exit(1)
	}

	// Run scans for IPv4 if present
	if len(ipv4Targets) > 0 {
		fmt.Println("\n--- Starting scans for IPv4 ---")
		for _, ip := range ipv4Targets {
			fmt.Printf("Scanning target: %s\n", ip)
			scanAndPrintResultsForIP(ip, portsToScan)
		}
	}

	// Run scans for IPv6 if present
	if len(ipv6Targets) > 0 {
		fmt.Println("\n--- Starting scans for IPv6 ---")
		for _, ip := range ipv6Targets {
			fmt.Printf("Scanning target: %s\n", ip)
			scanAndPrintResultsForIP(ip, portsToScan)
		}
	}

	duration := time.Since(startTime)
	fmt.Fprintf(os.Stderr, "Elapsed time: %.3f seconds.\n", duration.Seconds())
}

// scanAndPrintResultsForIP handles the scanning and ordered printing for a single IP
func scanAndPrintResultsForIP(ip net.IP, portsToScan []string) {
	results := make(chan string)
	var wg sync.WaitGroup

	for _, port := range portsToScan {
		wg.Add(2) // TCP and UDP
		go scanPort(ip.String(), port, "tcp", &wg, results)
		go scanPort(ip.String(), port, "udp", &wg, results)
	}

	// Start a goroutine to close the results channel once all scanning is done
	go func() {
		wg.Wait()
		close(results)
	}()

	// Collect and print results from the channel
	for result := range results {
		fmt.Println(result)
	}
	fmt.Println() // Add a blank line for spacing after each IP block
}

func printUsage() {
	fmt.Println("Usage: go run port_check.go [OPTIONS] <target>")
	fmt.Println("")
	fmt.Println("Options:")
	flag.PrintDefaults()
	fmt.Println("")
	fmt.Println("Targets:")
	fmt.Println("  IPv4 address     Direct IPv4 target")
	fmt.Println("  IPv6 address     Direct IPv6 target")
	fmt.Println("  Domain name       Will resolve to both IPv4 and IPv6 automatically")
	fmt.Println("")
	fmt.Println("Examples:")
	fmt.Println("  go run port_check.go -p 80,443 example.com")
	fmt.Println("  go run port_check.go -p 80,443 1.1.1.1")
}

func resolveTarget(target string) ([]net.IP, error) {
	if ip := net.ParseIP(target); ip != nil {
		return []net.IP{ip}, nil
	}

	var allIPs []net.IP
	resolver := net.Resolver{}

	// Explicitly look up IPv4 addresses
	ipv4s, err4 := resolver.LookupIP(context.Background(), "ip4", target)
	if err4 == nil {
		allIPs = append(allIPs, ipv4s...)
	}

	// Explicitly look up IPv6 addresses
	ipv6s, err6 := resolver.LookupIP(context.Background(), "ip6", target)
	if err6 == nil {
		allIPs = append(allIPs, ipv6s...)
	}

	// If both lookups failed, return an error
	if err4 != nil && err6 != nil {
		return nil, fmt.Errorf("could not resolve domain %s: %v", target, err4)
	}

	if len(allIPs) == 0 {
		return nil, fmt.Errorf("no IP addresses found for domain %s", target)
	}

	return allIPs, nil
}

func parsePorts(portStr string) ([]string, error) {
	ports := strings.Split(portStr, ",")
	if len(ports) == 0 {
		return nil, fmt.Errorf("no ports specified")
	}
	return ports, nil
}

// scanPort attempts to connect to a specific port and sends the result to a channel.
// Note: UDP scanning with this method is not always reliable. A timeout does not
// definitively mean a port is closed, as open UDP ports are not required to respond.
// The 'nmap' output 'open|filtered' is a more accurate representation of this uncertainty.
func scanPort(ip string, port string, protocol string, wg *sync.WaitGroup, results chan<- string) {
	defer wg.Done()
	// For IPv6, the address must be enclosed in square brackets.
	address := net.JoinHostPort(ip, port)
	timeout := 2 * time.Second
	conn, err := net.DialTimeout(protocol, address, timeout)

	if err != nil {
		// Do nothing if port is closed
		return
	}

	conn.Close()
	results <- fmt.Sprintf("% -5s % -10s %s", port, strings.ToUpper(protocol), "Open")
}
