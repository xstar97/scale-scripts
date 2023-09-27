#!/bin/bash

# Get a list of LoadBalancer IPs from k3s kubectl
ips=$(sudo k3s kubectl get svc -A | grep LoadBalancer | awk '{print $5}')

# Function to extract the last octet of an IP address
get_last_octet() {
    echo "$1" | awk -F. '{print $4}'
}

# Initialize variables to keep track of the largest IP and its last octet
largest_ip=""
largest_octet=0

# Iterate through the list of IPs to find the largest one
for ip in $ips; do
    octet=$(get_last_octet "$ip")
    if [ "$octet" -gt "$largest_octet" ]; then
        largest_ip="$ip"
        largest_octet="$octet"
    fi
done

# Increment the last octet of the largest IP by 1
next_octet=$((largest_octet + 1))

# Reconstruct the next IP address with the incremented octet
next_ip=$(echo "$largest_ip" | awk -F. -v var="$next_octet" '{$4 = var; print}' OFS='.')

echo "Next available IP: $next_ip"
