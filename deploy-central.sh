#!/bin/bash

set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# sudo apt-get install expect -y

for cmd in "minikube" "kubectl" "helm"; do
  type $cmd >/dev/null 2>&1 || { echo >&2 "$cmd required but it's not installed; aborting."; exit 1; }
done

DRIVER=${DRIVER-kvm}
DOMAIN=lgtm-central.cluster.local

if minikube status --profile=lgtm-central > /dev/null; then
  echo "Minikube already running"
else
  echo "Starting minikube"
  minikube start \
    --driver=$DRIVER \
    --container-runtime=containerd \
    --cpus=4 \
    --memory=8g \
    --addons=metrics-server \
    --addons=metallb \
    --dns-domain=$DOMAIN \
    --embed-certs=true \
    --profile=lgtm-central
fi

MINIKUBE_IP=$(minikube ip -p lgtm-central)
expect <<EOF
spawn minikube addons configure metallb -p lgtm-central
expect "Enter Load Balancer Start IP:" { send "${MINIKUBE_IP%.*}.201\\r" }
expect "Enter Load Balancer End IP:" { send "${MINIKUBE_IP%.*}.210\\r" }
expect eof
EOF

echo "Updating Helm Repositories"
helm repo add jetstack https://charts.jetstack.io
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update

echo "Setting up namespaces"
for ns in observability; do
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $ns
EOF
# kubectl create secret tls ingress-cert --namespace $ns \
#   --key=certs/ingress-tls.key --cert=certs/ingress-tls.crt -o yaml
done

echo "Deploying Nginx Ingress"
helm upgrade --install ingress-nginx nginx-stable/nginx-ingress \
  --namespace ingress-nginx --create-namespace -f values-ingress.yaml

echo "Deploying Apps"
./deploy-apps.sh