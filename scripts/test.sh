#!/usr/bin/env bash
set -euo pipefail

API_URL=${API_URL:-}

if [[ -z "$API_URL" ]]; then
	HOST=$(kubectl get svc claim-api -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
	IP=$(kubectl get svc claim-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)

	if [[ -n "$HOST" ]]; then
		API_URL="http://$HOST"
	elif [[ -n "$IP" ]]; then
		API_URL="http://$IP"
	else
		echo "❌ LoadBalancer not ready. Try again in a few minutes or set API_URL explicitly."
		exit 1
	fi
fi

echo "Using API_URL=$API_URL"

curl "$API_URL/claims/health"
curl "$API_URL/claims/CLM-1001"
curl -X POST "$API_URL/claims/CLM-1001/summarize"
