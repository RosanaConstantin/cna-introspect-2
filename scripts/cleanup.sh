#!/usr/bin/env bash
set -euo pipefail

kubectl delete -f k8s/hpa.yaml --ignore-not-found
kubectl delete -f k8s/claim-api-service.yaml --ignore-not-found
kubectl delete -f k8s/claim-api-deployment.yaml --ignore-not-found
kubectl delete -f k8s/claim-api-serviceaccount.yaml --ignore-not-found
