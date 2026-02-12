#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE=${AWS_PROFILE:-org-demo}
AWS_REGION=${AWS_REGION:-us-east-1}
API_NAME=${API_NAME:-claim-api}
STAGE_NAME=${STAGE_NAME:-prod}

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
OPENAPI_TEMPLATE="$ROOT_DIR/apigw/openapi.json"
OPENAPI_DEPLOYED="$ROOT_DIR/apigw/deployed-api.json"

echo "Setting up API Gateway for Claim API..."

# Get LoadBalancer URL
echo "Getting LoadBalancer endpoint..."
LB_HOST=$(kubectl get svc claim-api -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
LB_IP=$(kubectl get svc claim-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)

if [[ -n "$LB_HOST" ]]; then
  BACKEND_URL="http://$LB_HOST"
elif [[ -n "$LB_IP" ]]; then
  BACKEND_URL="http://$LB_IP"
else
  echo "❌ LoadBalancer not ready. Deploy claim-api first."
  exit 1
fi

echo "Backend URL: $BACKEND_URL"

# Update OpenAPI spec with backend URL
OPENAPI_FILE="$ROOT_DIR/apigw/openapi-with-backend.json"
sed "s|https://<INGRESS_OR_NLB>|$BACKEND_URL|g" "$OPENAPI_TEMPLATE" > "$OPENAPI_FILE"

# Check if API already exists
API_ID=$(aws apigateway get-rest-apis --region "$AWS_REGION" --profile "$AWS_PROFILE" \
  --query "items[?name=='$API_NAME'].id" --output text || true)

if [[ -n "$API_ID" ]]; then
  echo "API Gateway already exists (ID: $API_ID). Updating..."
  aws apigateway put-rest-api \
    --rest-api-id "$API_ID" \
    --mode overwrite \
    --body "fileb://$OPENAPI_FILE" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" >/dev/null
else
  echo "Creating new API Gateway..."
  API_ID=$(aws apigateway import-rest-api \
    --body "fileb://$OPENAPI_FILE" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" \
    --query 'id' --output text)
  
  # Update name if needed
  aws apigateway update-rest-api \
    --rest-api-id "$API_ID" \
    --patch-operations op=replace,path=/name,value="$API_NAME" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" >/dev/null || true
fi

echo "API ID: $API_ID"

# Create deployment
echo "Deploying API to stage '$STAGE_NAME'..."
aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name "$STAGE_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" >/dev/null

# Get invoke URL
INVOKE_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${STAGE_NAME}"

echo ""
echo "✅ API Gateway deployed successfully!"
echo "API ID: $API_ID"
echo "Stage: $STAGE_NAME"
echo "Invoke URL: $INVOKE_URL"
echo ""
echo "Test endpoints:"
echo "  curl $INVOKE_URL/claims/health"
echo "  curl $INVOKE_URL/claims/CLM-1001"
echo "  curl -X POST $INVOKE_URL/claims/CLM-1001/summarize"

# Export deployed API spec
echo ""
echo "Exporting deployed API configuration..."
aws apigateway get-export \
  --rest-api-id "$API_ID" \
  --stage-name "$STAGE_NAME" \
  --export-type oas30 \
  --accepts application/json \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  "$OPENAPI_DEPLOYED"

echo "✅ Exported to: $OPENAPI_DEPLOYED"
