#!/bin/bash

set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# sudo apt-get install expect -y

for cmd in "minikube" "kubectl" "helm"; do
  type $cmd >/dev/null 2>&1 || { echo >&2 "$cmd required but it's not installed; aborting."; exit 1; }
done

https://github.com/rancher/rke/releases/download/v1.4.5/rke_linux-amd64


echo "Updating Helm Repositories"
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add minio https://charts.min.io/
helm repo add metallb https://metallb.github.io/metallb
helm repo update


helm upgrade --install metallb metallb/metallb --namespace metallb-system --create-namespace
kubectl apply -f ip-address-pool.yaml

echo "Deploying Nginx Ingress"
helm upgrade --install ingress-nginx nginx-stable/nginx-ingress \
  --namespace ingress-nginx --create-namespace -f values/nginx-ingress.yaml

echo "Setting up namespaces"
for ns in observability storage tempo loki mimir app; do
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $ns
EOF
kubectl create secret tls ingress-cert --namespace $ns \
  --key=certs/ingress-tls.key --cert=certs/ingress-tls.crt -o yaml
done

echo "Deploying Prometheus CRDs"
./deploy-prometheus-crds.sh

echo "Deploying Prometheus (for Local Metrics)"
helm upgrade --install monitor prometheus-community/kube-prometheus-stack \
  -n observability -f values/prometheus-common.yaml -f values/prometheus-central.yaml --wait

echo "Deploying Sample App"
kubectl apply -f app/sample-app.yaml

echo "Create Ingress resources"
kubectl apply -f ingress-central.yaml

INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Remember to add entries to /etc/hosts pointing to $INGRESS_IP to test the Ingress resources"