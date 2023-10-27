#!/bin/bash

# Define the base URL and PORT, default is 80
# just change the port # if running on scale, otherwise change to the IP too.
BASE_URL="http://localhost:80"

# Define the Authorization token
# go to scale's /ui/apikeys and create an api key
AUTH_TOKEN="Bearer CHANGE_ME"

# Define the SMB_USER
# the username with samba auth
# not root or admin!
SMB_USER="CHANGE_ME"

# Aux param perms
AUX_USER=apps
AUX_GROUP=apps

# Make the API request using cURL and extract the JSON array
response=$(curl -X 'GET' "${BASE_URL}/api/v2.0/sharing/smb" -H 'accept: application/json' -H "Authorization: ${AUTH_TOKEN}")

# Parse the JSON array and extract "id" and "path" values into an associative array
declare -A smb_shares
while IFS= read -r line; do
    id=$(jq -r '.id' <<< "$line")
    path=$(jq -r '.path' <<< "$line")
    smb_shares["$id"]=$path
done <<< "$(echo "$response" | jq -c '.[]')"

# Sort the associative array by id
sorted_smb_shares=($(for id in "${!smb_shares[@]}"; do
  echo "$id:${smb_shares[$id]}"
done | sort))

# Loop through the sorted list
for item in "${sorted_smb_shares[@]}"; do
    id="${item%%:*}"
    path="${item#*:}"
    echo "SMB Share ID: $id"
    echo "SMB Share path: $path"

    # Ask the user for input
    read -p "Do you want to update this smb share auxillary params? (y/n): " user_input

    if [ "$user_input" == "y" ]; then

        # Construct and run the cURL command to update the SMB share parameters
        curl -X PUT "${BASE_URL}/api/v2.0/sharing/smb/id/$id" \
            -H 'accept: application.json' \
            -H "Authorization: $AUTH_TOKEN" \
            -H 'Content-Type: application/json' \
            --data "{\"auxsmbconf\": \"force user=$AUX_USER\nforce group=$AUX_GROUP\nvalid users=$SMB_USER\"}" > /dev/null 2>&1
       echo "smb share: $path was updated."
    fi
done

echo "Script completed."
