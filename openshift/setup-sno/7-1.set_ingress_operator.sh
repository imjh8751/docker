#!/bin/bash

# Set the namespace
NAMESPACE="openshift-ingress-operator"

# Patch the IngressController to add node placement
oc patch ingresscontroller default -n "$NAMESPACE" --type=merge -p '{
    "spec": {
        "nodePlacement": {
            "nodeSelector": {
                "matchLabels": {
                    "node-role.kubernetes.io/worker": ""
                }
            }
        }
    }
}'

# Check the result
if [ $? -eq 0 ]; then
    echo "IngressController node placement updated successfully."
    oc get ingresscontroller default -n "$NAMESPACE" -o yaml | grep -A5 "nodePlacement:"
else
    echo "Failed to update IngressController node placement."
    exit 1
fi
