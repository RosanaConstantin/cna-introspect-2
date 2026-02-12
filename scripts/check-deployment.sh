#!/usr/bin/env bash
set -euo pipefail

kubectl get pods
kubectl get svc claim-api
kubectl get hpa
