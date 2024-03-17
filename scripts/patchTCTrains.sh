#!/bin/bash

# Initialize counter for updated charts
updated_count=0

echo "Starting namespace updates..."

# Loop through all namespaces prefixed by "ix-"
for ns in $(k3s kubectl get namespaces -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep '^ix-'); do
    echo "Processing namespace: $ns"
    
    # Check if the namespace has "catalog_train" label set to "enterprise" or "operators"
    catalog_train_label=$(k3s kubectl get namespace "$ns" -o jsonpath='{.metadata.labels.catalog_train}')
    
    if [[ "$catalog_train_label" == "enterprise" ]]; then
        # Patch the namespace to change the "catalog_train" label to "premium"
        k3s kubectl patch namespace "$ns" -p '{"metadata":{"labels":{"catalog_train":"premium"}}}'
        echo "Namespace $ns updated from enterprise to premium."
        ((updated_count++))
    elif [[ "$catalog_train_label" == "operators" ]]; then
        # Patch the namespace to change the "catalog_train" label to "system"
        k3s kubectl patch namespace "$ns" -p '{"metadata":{"labels":{"catalog_train":"system"}}}'
        echo "Namespace $ns updated from operators to system."
        ((updated_count++))
    fi
done

if [[ "$updated_count" -eq 0 ]]; then
    echo "No charts needed the patch."
fi

echo "Namespace updates completed."
echo "Total number of charts updated: $updated_count"
