#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE=${AWS_PROFILE:-org-demo}
AWS_REGION=${AWS_REGION:-us-east-1}
API_NAME="Claim Status API"

echo "Testing API Gateway endpoints..."

# Get API ID
API_ID=$(aws apigateway get-rest-apis --region "$AWS_REGION" --profile "$AWS_PROFILE" \
  --query "items[?name=='$API_NAME'].id" --output text 2>/dev/null || true)

if [[ -z "$API_ID" ]]; then
  echo "❌ API Gateway not found. Run setup-apigw.sh first."
  exit 1
fi

STAGE_NAME=${STAGE_NAME:-prod}
INVOKE_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${STAGE_NAME}"

echo "Using API Gateway URL: $INVOKE_URL"
echo ""

echo "1. Health check..."
curl -s "$INVOKE_URL/claims/health" | jq '.' || curl -s "$INVOKE_URL/claims/health"

echo ""
echo "2. Get claim CLM-1001..."
curl -s "$INVOKE_URL/claims/CLM-1001" | jq '.' || curl -s "$INVOKE_URL/claims/CLM-1001"

echo ""
echo "3. Summarize claim CLM-1001..."
curl -s -X POST "$INVOKE_URL/claims/CLM-1001/summarize" | jq '.' || curl -s -X POST "$INVOKE_URL/claims/CLM-1001/summarize"

echo ""
echo "✅ API Gateway tests completed"
