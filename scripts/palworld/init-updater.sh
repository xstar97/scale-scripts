#!/bin/bash

# Default values for config paths, can be overridden
configPath="${configPath:-/serverdata/serverfiles/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini}"
defaultConfigPath="${defaultConfigPath:-/serverdata/serverfiles/DefaultPalWorldSettings.ini}"

if [ ! -f "${configPath}" ]; then
    echo "Config file not found, copying default file..."
    cp -r "${defaultConfigPath}" "${configPath}"
fi

if [ ! -f "${cfgFile}" ]; then
    echo "Config file not found, copying default file..."
    cp -r "${dfCfgFile}" "${cfgFile}"
fi

set_ini_value() {
    local key
    local value
    local quote_flag=false
    local special_characters=false

    # Parse flags
    while getopts ":qsc" opt; do
        case ${opt} in
            q) quote_flag=true ;;
            sc) special_characters=true ;;
            \?) echo "Invalid option: -$OPTARG" >&2 ;;
        esac
    done
    shift $((OPTIND -1))

    key="${1}"
    value="${2}"

    # Check if the quote flag is set
    if [ "$quote_flag" = true ]; then
        # Add quotes around the value
        value="\"$value\""
    fi

    if [ "$special_characters" = true ]; then
        echo "Setting ${key}..."
        awk -v key="$key" -v value="$value" 'BEGIN {FS=OFS="="} $1 == key {gsub(/[^=]+$/, "\"" value "\"")} 1' "${cfgFile}" > "${cfgFile}.tmp" && mv "${cfgFile}.tmp" "${cfgFile}"
        echo "Set to $(grep -Po "(?<=${key}=)[^,]*" "${cfgFile}")"
    else
        echo "Setting ${key}..."
        sed -i "s|\(${key}=\)[^,]*|\1${value}|g" "${cfgFile}"
        echo "Set to $(grep -Po "(?<=${key}=)[^,]*" "${cfgFile}")"
    fi
}

get_ini_value() {
    local key="${1}"

    # Output only the value of the key
    grep -Po "(?<=${key}=)[^,]*" "${cfgFile}"
}

get_ini_value_all() {
    # Extract keys and values from the specified section
    sed -n '/\[\/Script\/Pal.PalGameWorldSettings\]/,/^\[/p' "${cfgFile}" | grep -Po '(?<=\()[^)]*' | tr ',' '\n' | sed 's/=/=/g'
}

# Check if the number of arguments is valid for both set and get options
if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
    echo "Usage:"
    echo "To set a value: $0 set <key> <value> [-q] [-sc]"
    echo "To get a value: $0 get <key>"
    echo "To get all key-value pairs: $0 getall"
    exit 1
fi

# Check the option provided (set or get)
option="$1"
shift

case "$option" in
    "set")
        # Check if two arguments are provided for set option
        if [ "$#" -lt 2 ]; then
            echo "Usage for set option: $0 set <key> <value> [-q] [-sc]"
            exit 1
        fi
        set_ini_value "$@"
        ;;
    "get")
        # Check if one argument is provided for get option
        if [ "$#" -ne 1 ]; then
            echo "Usage for get option: $0 get <key>"
            exit 1
        fi
        get_ini_value "$1"
        ;;
    "getall")
        # No arguments needed for getall option
        if [ "$#" -ne 0 ]; then
            echo "Usage for getall option: $0 getall"
            exit 1
        fi
        get_ini_value_all
        ;;
    *)
        echo "Invalid option: $option"
        echo "Usage:"
        echo "To set a value: $0 set <key> <value> [-q] [-sc]"
        echo "To get a value: $0 get <key>"
        echo "To get all key-value pairs: $0 getall"
        exit 1
        ;;
esac
