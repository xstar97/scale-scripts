#!/bin/bash

dry_run=false

# Function to get chart names
get_chart_names() {
    cli -m csv -c 'app chart_release query name' | tail -n +2 | sort | tr -d " \t\r" | awk 'NF'
}

update_storage_class(){
    local app_name=$1
    local json=$2

    if ! $dry_run; then
        cli -c "app chart_release update chart_release=\"$app_name\" values=$json"
    else
        echo "Dry run: Not executing the command."
    fi
}
update_json_data(){
    local json_key=$1
    local app_name=$2
    local json=$3

    if [[ $json_key == "persistence" ]]; then
        local updated_json=$(echo "$json" | jq --arg storageClass "SCALE-ZFS" '
            with_entries(
                if .value | type == "object" then
                    .value |= if .storageClass == "" then .storageClass = $storageClass else . end
                else
                    .
                end
            )
        ' | jq '{"persistence": .}')
        echo "$updated_json"
        update_storage_class "$app_name" "$updated_json"
    elif [[ $json_key == "persistenceList" ]]; then
        local updated_json=$(echo "$json" | jq 'map(if .storageClass == "" then .storageClass = "SCALE-ZFS" else . end)' | jq '{"persistenceList": .}')
        echo "$updated_json"
        update_storage_class "$app_name" "$updated_json"
    fi
}

filter_chart() {
    local app_name=$1
    local config=$(midclt call chart.release.get_instance "$app_name" | jq -r '.config')

    # Check if the config is null
    if [[ $config == "null" ]]; then
        echo "Skipping $app_name... (No config found)"
        return
    fi

    # Extract persistence and persistenceList
    local persistence=$(echo "$config" | jq -r '.persistence')

    # Check if persistence is null
    if [[ $persistence != "null" ]]; then
        # Check each object within persistence for storageClass
        local empty_storage_class_found=false
        while IFS= read -r object; do
            local storage_class=$(echo "$object" | jq -r '.storageClass')
            if [[ -z $storage_class ]]; then
                empty_storage_class_found=true
                break
            fi
        done < <(echo "$persistence" | jq -c '.[]')

        if $empty_storage_class_found; then
            echo "Updating chart PVC data with SCALE-ZFS for the storageClass for $app_name (persistence)"

            if ! $dry_run; then
                # Update the storageClass here
                echo "At least one empty storageClass found. Updating..."
                update_json_data "persistence" "$app_name" "$persistence"
            else
                echo "Dry run: Not executing the update."
            fi
        else
            echo "StorageClass is not empty for $app_name in persistence. Skipping update."
        fi
    fi

    # Check if storageClass is empty in persistenceList
    local persistenceList=$(echo "$config" | jq -r '.persistenceList')
    if [[ $persistenceList != "null" ]]; then
        local empty_storage_classes=$(echo "$persistenceList" | jq -r 'map(select(.storageClass == "")) | length')
        if [[ $empty_storage_classes -gt 0 ]]; then
            echo "Updating storageClass for persistenceList items in $app_name"

            if ! $dry_run; then
                # Update the storageClass for persistenceList here
                echo "At least one empty storageClass found. Updating..."
                update_json_data "persistenceList" "$app_name" "$persistenceList"
            else
                echo "Dry run: Not executing the update."
            fi
        fi
    fi
}

# Check if the flag --dry-run is set
if [[ $1 == "--dry-run" ]]; then
    dry_run=true
    shift  # Remove the --dry-run flag from the arguments
fi

# Check if the flag --app is set
if [[ $1 == "--app" ]]; then
    filter_chart "$2"
else
    # Echo the name of each chart
    get_chart_names | while read -r chart_name; do
        filter_chart "$chart_name"
    done
fi
