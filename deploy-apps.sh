#!/bin/bash

set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Update Apps
echo "Deploying Sample App"
kubectl apply -f app/sample-app.yaml

# Update Ingress
echo "Create Ingress resources"
kubectl apply -f ingress-central.yaml

# Update DNS
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Remember to add entries to /etc/hosts pointing to $INGRESS_IP to test the Ingress resources"
