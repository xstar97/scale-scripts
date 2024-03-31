#!/bin/bash

    # get namespaces
    namespaces=$(k3s kubectl get secrets -A | grep -E "dbcreds|cnpg-main-urls" | awk '{print $1, $2}')

    # iterate over namespaces
    ( printf "Application | Username | Password | Address | Port\n"
    echo "$namespaces" | while read ns secret; do
        # extract application name
        app_name=$(echo "$ns" | sed 's/^ix-//')
        if [ "$secret" = "dbcreds" ]; then
            creds=$(k3s kubectl get secret/$secret --namespace "$ns" -o jsonpath='{.data.url}' | base64 -d)
        else
            creds=$(k3s kubectl get secret/$secret --namespace "$ns" -o jsonpath='{.data.std}' | base64 -d)
        fi

        # get username, password, addresspart, and port
        username=$(echo "$creds" | awk -F '//' '{print $2}' | awk -F ':' '{print $1}')
        password=$(echo "$creds" | awk -F ':' '{print $3}' | awk -F '@' '{print $1}')
        addresspart=$(echo "$creds" | awk -F '@' '{print $2}' | awk -F ':' '{print $1}')
        port=$(echo "$creds" | awk -F ':' '{print $4}' | awk -F '/' '{print $1}')

        # construct full address
        full_address="${addresspart}.${ns}.svc.cluster.local"

        # print results with aligned columns
        printf "%s | %s | %s | %s | %s\n" "$app_name" "$username" "$password" "$full_address" "$port"
    done ) | column -t -s "|"
    
