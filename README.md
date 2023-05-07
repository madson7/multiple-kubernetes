# Kultiple Kubernetes
Playground for multiple Kubernetes clusters

minikube delete -p central
minikube delete -p lgtm-remote

mkdir certs
openssl req -x509 -nodes -days 9999 -newkey rsa:2048 -keyout certs/ingress-tls.key -out certs/ingress-tls.crt

