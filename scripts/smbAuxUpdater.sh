#!/bin/bash

# Define the base URL and PORT, default is 80
# just change the port # if running on scale, otherwise change to the IP too.
BASE_URL="http://localhost:80"

# Bearer for token
# Basic for user auth
# leave default
AUTH_TYPE="Bearer"
# Define the Authorization token/value
# go to scale's /ui/apikeys and create an api key
AUTH_VALUE="CHANGE_ME"

# Define the SMB users
# the username with samba auth
# not root or admin!
# comma separated user list
SMB_USERS="CHANGE_ME"

# Aux param perms
# default perms
AUX_USER=apps
AUX_GROUP=apps

# API routes
GET_SMB_SHARES_ROUTE="/api/v2.0/sharing/smb"
UPDATE_SMB_SHARE_ROUTE="$GET_SMB_SHARES_ROUTE/id"

# Function to make the API request using cURL and extract the JSON array
make_api_request() {
    curl -X 'GET' "${BASE_URL}${GET_SMB_SHARES_ROUTE}" -H 'accept: application/json' -H "Authorization: $AUTH_TYPE ${AUTH_VALUE}"
}

# Function to update SMB share parameters
update_smb_share() {
    local id="$1"
    local path="$2"

    # Construct and run the cURL command to update the SMB share parameters
    curl -X PUT "${BASE_URL}${UPDATE_SMB_SHARE_ROUTE}/$id" \
        -H 'accept: application.json' \
        -H "Authorization: $AUTH_TYPE $AUTH_VALUE" \
        -H 'Content-Type: application/json' \
        --data "{\"auxsmbconf\": \"force user=$AUX_USER\nforce group=$AUX_GROUP\nvalid users=$SMB_USERS\"}" > /dev/null 2>&1

    echo "SMB share: $path was updated."
}

# Function to process SMB shares
process_smb_shares() {
    local response="$1"

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
        read -p "Do you want to update this SMB share auxiliary params? (y/n): " user_input

        if [ "$user_input" == "y" ]; then
            update_smb_share "$id" "$path"
        fi
    done
}

# Main execution
response=$(make_api_request)
process_smb_shares "$response"
echo "Script completed."
