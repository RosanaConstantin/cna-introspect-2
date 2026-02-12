#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

kubectl apply -f "$ROOT_DIR/k8s/claim-api-serviceaccount.yaml"
kubectl apply -f "$ROOT_DIR/k8s/claim-api-deployment.yaml"
kubectl apply -f "$ROOT_DIR/k8s/claim-api-service.yaml"
kubectl apply -f "$ROOT_DIR/k8s/hpa.yaml"
