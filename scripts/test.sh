#!/usr/bin/env bash
set -euo pipefail

API_URL=${API_URL:-http://localhost}

curl "$API_URL/claims/health"
curl "$API_URL/claims/CLM-1001"
curl -X POST "$API_URL/claims/CLM-1001/summarize"
