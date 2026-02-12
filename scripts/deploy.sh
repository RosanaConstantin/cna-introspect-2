#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f k8s/claim-api-deployment.yaml
kubectl apply -f k8s/claim-api-service.yaml
kubectl apply -f k8s/hpa.yaml
