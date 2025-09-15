#!/bin/bash
set -e

# Update packages
apt-get update -y
apt-get upgrade -y

# Install dependencies
apt-get install -y snapd openssl git

# Install MicroK8s
snap install microk8s --classic --channel=1.30/stable

# Wait until MicroK8s is ready
microk8s status --wait-ready

# Enable required addons
microk8s enable dns ingress

# Generate self-signed TLS cert
mkdir -p /etc/ssl/httpbin
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/httpbin/tls.key \
  -out /etc/ssl/httpbin/tls.crt \
  -subj "/CN=httpbin.local/O=httpbin"

# Create Kubernetes namespace
microk8s kubectl create ns httpbin || true

# Create Kubernetes TLS secret
microk8s kubectl -n httpbin create secret tls httpbin-tls \
  --cert=/etc/ssl/httpbin/tls.crt \
  --key=/etc/ssl/httpbin/tls.key || true

# === auto-fetch manifests from GitHub so that no errors in /home/ubuntu ===
cd /home/ubuntu
git clone https://github.com/bavly/aws-httpbin-project.git k8s-repo
cd k8s-repo/k8s

# Apply Kubernetes manifests
microk8s kubectl apply -n httpbin -f httpbin-deployment.yaml
microk8s kubectl apply -n httpbin -f httpbin-service-public.yaml
microk8s kubectl apply -n httpbin -f httpbin-service-private.yaml
microk8s kubectl apply -n httpbin -f httpbin-ingress.yaml
