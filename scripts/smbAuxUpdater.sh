#!/bin/bash

# Default variable for auxiliary SMB configuration
auxsmbconfuser="force user = apps\nforce group = apps"

# Function to update auxsmbconf for a specific SMB share
update_auxsmbconf() {
    local id="$1"
    local conf="$2"

    echo "Updating auxsmbconf for ID: $id..."
    if midclt call sharing.smb.update "$id" "{\"auxsmbconf\": \"$conf\"}"; then
        echo "Successfully updated auxsmbconf for ID: $id."
    else
        echo "Failed to update auxsmbconf for ID: $id."
    fi
}

# Function to fetch a list of SMB shares and check if an ID exists
get_share_by_id() {
    local id="$1"
    midclt call sharing.smb.query | jq -e ".[] | select(.id == $id)" > /dev/null 2>&1
}

# Function to display SMB shares in a simple list format
display_shares() {
    midclt call sharing.smb.query | jq -r \
        '.[] | "\(.id).\n  PATH: \(.path)\n  NAME: \(.name)\n  AUXSMBCONF: \(.auxsmbconf // "None")\n"'
}

# Parse command-line flags
list_shares=false
remove_aux=false
auto_yes=false
choice=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list)
            list_shares=true
            ;;
        --id)
            choice="$2"
            shift
            ;;
        --user)
            if [[ -n "$2" ]]; then
                auxsmbconfuser="force user = $2\nforce group = $2"
                shift
            else
                echo "Error: --user requires a user/group value."
                exit 1
            fi
            ;;
        --remove-aux)
            remove_aux=true
            ;;
        --yes)
            auto_yes=true
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Always list shares first if --list is specified
if [[ "$list_shares" == true ]]; then
    display_shares
    exit 0  # Ensure it exits after listing
fi

# Function to handle removal with optional confirmation
remove_auxsmbconf() {
    local id="$1"
    if [[ "$auto_yes" == true ]]; then
        update_auxsmbconf "$id" ""
    else
        read -r -p "Are you sure you want to remove auxsmbconf for ID $id? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            update_auxsmbconf "$id" ""
        else
            echo "Operation canceled."
        fi
    fi
}

# If --remove-aux is specified, ensure an ID is provided
if [[ "$remove_aux" == true ]]; then
    if [[ -n "$choice" ]]; then
        if get_share_by_id "$choice"; then
            remove_auxsmbconf "$choice"
        else
            echo "No SMB share found with ID: $choice."
        fi
    else
        echo "Error: --remove-aux requires --id to specify the share ID."
    fi
    exit 0
fi

# If --id is provided, process the update
if [[ -n "$choice" ]]; then
    if get_share_by_id "$choice"; then
        if [[ "$remove_aux" == true ]]; then
            remove_auxsmbconf "$choice"
        else
            update_auxsmbconf "$choice" "$auxsmbconfuser"
        fi
    else
        echo "No SMB share found with ID: $choice."
    fi
    exit 0
fi

# Interactive mode only if no --id is provided
while true; do
    display_shares
    read -r -p "Enter the ID of the SMB share to update or 'q' to quit: " choice
    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        echo "Exiting..."
        exit 0
    elif [[ "$choice" =~ ^[0-9]+$ ]]; then
        if get_share_by_id "$choice"; then
            if [[ "$remove_aux" == true ]]; then
                remove_auxsmbconf "$choice"
            else
                update_auxsmbconf "$choice" "$auxsmbconfuser"
            fi
        else
            echo "No SMB share found with ID: $choice."
        fi
    else
        echo "Invalid input. Please enter a valid numeric ID or 'q' to quit."
    fi
done
