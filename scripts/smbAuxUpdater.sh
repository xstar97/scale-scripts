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

# Aux param perms | leave default
AUX_USER=apps
AUX_GROUP=apps

# Make the API request using cURL and extract the CSV list
response=$(curl -X 'GET' "${BASE_URL}/api/v2.0/sharing/smb" -H 'accept: application/json' -H "Authorization: ${AUTH_TOKEN}")
output=$(echo "$response" | jq -r '.[] | "\(.id),\(.path_local)"')

# Loop through the CSV list
IFS=$'\n' read -ra csv_values <<< "$output"
completed="no"
for value in "${csv_values[@]}"; do
    IFS=',' read -r id path_local <<< "$value"
    echo "ID: $id"
    echo "Update this smb share's $path_local Auxillary params?"

    # Ask the user for input
    read -p "Do you want to run the command for this ID? (y/n): " user_input

    if [ "$user_input" == "y" ]; then

        # Construct and run the cURL command to update the SMB share parameters
        curl -X PUT "${BASE_URL}/api/v2.0/sharing/smb/id/$id" \
            -H 'accept: application/json' \
            -H "Authorization: $AUTH_TOKEN" \
            -H 'Content-Type: application/json' \
            --data "{\"auxsmbconf\": \"force user=$AUX_USER\nforce group=$AUX_GROUP\nvalid users=$SMB_USER\"}" > /dev/null 2>&1
        completed="yes"
    fi
done

if [ "$completed" == "yes" ]; then
    echo -e "\nScript completed successfully."
else
    echo -e "\nScript aborted."
fi
