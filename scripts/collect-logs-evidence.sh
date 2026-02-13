#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE=${AWS_PROFILE:-org-demo}
AWS_REGION=${AWS_REGION:-us-east-1}

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
OBSERVABILITY_DIR="$ROOT_DIR/observability"

echo "Collecting CloudWatch Logs evidence..."

mkdir -p "$OBSERVABILITY_DIR/logs"

# Get pod names
POD_NAME=$(kubectl get pods -l app=claim-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [[ -z "$POD_NAME" ]]; then
  echo "❌ No claim-api pods found"
  exit 1
fi

echo "Found pod: $POD_NAME"

# Get recent logs from pod
echo "Fetching recent application logs..."
kubectl logs "$POD_NAME" -c claim-api --tail=100 > "$OBSERVABILITY_DIR/logs/claim-api-recent.log"

# Get EKS cluster log groups
echo "Listing CloudWatch log groups..."
aws logs describe-log-groups \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --query 'logGroups[?contains(logGroupName, `eks`) || contains(logGroupName, `claim`)].logGroupName' \
  --output json > "$OBSERVABILITY_DIR/log-groups.json"

echo ""
echo "✅ CloudWatch evidence collected in $OBSERVABILITY_DIR"
echo ""
echo "Log files:"
ls -lh "$OBSERVABILITY_DIR/logs/" || true
echo ""
echo "Next steps:"
echo "1. Run CloudWatch Logs Insights queries from observability/queries.md"
echo "2. Document query results in your validation report"
