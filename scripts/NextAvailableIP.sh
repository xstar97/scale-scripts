#!/bin/bash

list_apps=false
test_mode=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    list-apps)
      list_apps=true
      shift
      ;;
    --test)
      test_mode=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [ "$test_mode" = true ]; then
  # Example list for testing
  example_list="traefik-tcp                    10.0.0.178
fileflows                      10.0.0.174
plex                           10.0.0.175"

  ip_list=$(echo "$example_list" | awk '{ printf "%-30s %-15s\n", $1, $2 }')
else
  # Run the command and store the output in a variable
  svc_output=$(sudo k3s kubectl get svc -A)

  # Extract the list of IPs from the output
  ip_list=$(echo "$svc_output" | awk '$3 == "LoadBalancer" { printf "%-30s %-15s\n", $2, $5 }')
fi

# Convert the list of IPs to an array
IFS=$'\n' read -r -a ips <<< "$ip_list"

# Extract just the IP addresses from the list
ip_addresses=($(echo "$ip_list" | awk '{print $NF}'))

# Sort the IPs
sorted_ips=($(printf '%s\n' "${ip_addresses[@]}" | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n))

# Find the next available IP
next_ip=""
previous_ip=""

for ((i = 0; i < ${#sorted_ips[@]}; i++)); do
  current_ip="${sorted_ips[$i]}"
  IFS=. read -ra current_ip_parts <<< "$current_ip"

  # Calculate the expected next IP
  expected_next_octet=$(( ${current_ip_parts[3]} + 1 ))
  expected_next_ip="${current_ip_parts[0]}.${current_ip_parts[1]}\
.${current_ip_parts[2]}.$expected_next_octet"

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
  next_ip="${largest_ip_parts[0]}.${largest_ip_parts[1]}\
.${largest_ip_parts[2]}.$next_octet"
fi

# Print the formatted IP list and the next available IP
if [ "$list_apps" = true ]; then
  echo "App List:"
  echo "$ip_list"
fi

echo "Next available IP: $next_ip"
