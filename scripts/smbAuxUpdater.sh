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

# Function to fetch SMB shares as an array
get_shares_list() {
    midclt call sharing.smb.query | jq -r '.[] | "\(.id):\(.name)"'
}

# Function to handle removal of auxsmbconf
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

# Parse command-line flags
list_shares=false
manual_id=""
remove_aux=false
auto_yes=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list)
            list_shares=true
            ;;
        --id)
            manual_id="$2"
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

# If --list is specified, display SMB shares and exit
if [[ "$list_shares" == true ]]; then
    get_shares_list
    exit 0
fi

# If --id is specified, update or remove the specific share
if [[ -n "$manual_id" ]]; then
    if midclt call sharing.smb.query | jq -e ".[] | select(.id == $manual_id)" > /dev/null 2>&1; then
        if [[ "$remove_aux" == true ]]; then
            remove_auxsmbconf "$manual_id"
        else
            update_auxsmbconf "$manual_id" "$auxsmbconfuser"
        fi
    else
        echo "No SMB share found with ID: $manual_id."
    fi
    exit 0
fi

# Display available SMB shares using select
mapfile -t shares < <(get_shares_list)
if [[ ${#shares[@]} -eq 0 ]]; then
    echo "No SMB shares found."
    exit 1
fi

echo "Select an SMB share to update:"
select share in "${shares[@]}" "Quit"; do
    if [[ "$share" == "Quit" ]]; then
        echo "Exiting..."
        exit 0
    elif [[ -n "$share" ]]; then
        choice="${share%%:*}" # Extract the ID from "id:name"
        if [[ "$remove_aux" == true ]]; then
            remove_auxsmbconf "$choice"
        else
            update_auxsmbconf "$choice" "$auxsmbconfuser"
        fi
        exit 0
    else
        echo "Invalid selection. Try again."
    fi
done
