#!/bin/bash

# Function to find the next available IP
find_next_available_ip() {
    local start_ip="$1"
    local end_ip="$2"
    
    # Get the load balancer IPs from the command
    load_balancer_ips=$(sudo k3s kubectl get svc -A | grep LoadBalancer | awk '{print $5}')
    
    # Loop through the range of IPs and find the first available IP
    for ip in $(seq -f "%g" $(echo "$start_ip" | cut -d'.' -f4) $(echo "$end_ip" | cut -d'.' -f4)); do
        local ip_to_check="$(echo "$start_ip" | cut -d'.' -f1-3).$ip"
        # Check if the IP is not in use
        if ! echo "$load_balancer_ips" | grep -q "$ip_to_check"; then
            next_ip="$((ip + 1))"
            next_ip="$(echo "$start_ip" | cut -d'.' -f1-3).$next_ip"
            
            # Check if the next IP exceeds the end range
            if [[ "$(echo "$next_ip" | cut -d'.' -f4)" -le "$(echo "$end_ip" | cut -d'.' -f4)" ]]; then
                echo "Next available IP: $next_ip"
                exit 0
            else
                echo "Next available IP exceeds the end range ($end_ip)."
                echo "Consider increasing the IP range in metallb-config."
                exit 1
            fi
        fi
    done

    # If all IPs in the range are in use, issue a warning
    echo "All IPs in the range $start_ip - $end_ip are in use."
    echo "Consider increasing the IP range in metallb-config."
    exit 1
}

# Check if an IP range argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <ip_range>"
    exit 1
fi

# Extract the start and end IPs from the input range
IP_RANGE="$1"
START_IP=$(echo "$IP_RANGE" | cut -d'-' -f1)
END_IP=$(echo "$IP_RANGE" | cut -d'-' -f2)

# Call the function to find the next available IP
find_next_available_ip "$START_IP" "$END_IP"
