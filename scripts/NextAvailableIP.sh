#!/bin/bash

# Get the last LoadBalancer IP from k3s kubectl
last_ip=$(sudo k3s kubectl get svc -A | grep LoadBalancer | awk '{print $5}' | tail -n 1)

# Extract the last octet of the IP address
last_octet=$(echo "$last_ip" | awk -F. '{print $4}')

# Increment the last octet by 1
next_octet=$((last_octet + 1))

# Reconstruct the IP address with the incremented octet
next_ip=$(echo "$last_ip" | awk -F. -v var="$next_octet" '{$4 = var; print}' OFS='.')

echo "Next available IP: $next_ip"
