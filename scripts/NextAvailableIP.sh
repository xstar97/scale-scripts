#!/bin/bash

# Run the command and store the output in a variable
svc_output=$(sudo k3s kubectl get svc -A)

# Extract the list of IPs from the output
ip_list=$(echo "$svc_output" | grep LoadBalancer | awk '{print $5}')

# Convert the list of IPs to an array
IFS=$'\n' read -r -a ips <<< "$ip_list"

# Sort the IPs
sorted_ips=($(printf '%s\n' "${ips[@]}" | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n))

# Find the next available IP
next_ip=""
previous_ip=""

for ((i = 0; i < ${#sorted_ips[@]}; i++)); do
  current_ip="${sorted_ips[$i]}"
  IFS=. read -ra current_ip_parts <<< "$current_ip"

  # Calculate the expected next IP
  expected_next_octet=$(( ${current_ip_parts[3]} + 1 ))
  expected_next_ip="${current_ip_parts[0]}.${current_ip_parts[1]}.${current_ip_parts[2]}.$expected_next_octet"

  if [ "$expected_next_ip" != "${sorted_ips[$((i + 1))]}" ]; then
    next_ip="$expected_next_ip"
    break
  fi
done

if [ -z "$next_ip" ]; then
  # No available IP found, so use the largest IP
  largest_ip="${sorted_ips[-1]}"
  IFS=. read -ra largest_ip_parts <<< "$largest_ip"
  next_octet=$(( ${largest_ip_parts[3]} + 1 ))
  next_ip="${largest_ip_parts[0]}.${largest_ip_parts[1]}.${largest_ip_parts[2]}.$next_octet"
fi

echo "Next available IP: $next_ip"
