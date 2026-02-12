#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE=${AWS_PROFILE:-org-demo}
AWS_REGION=${AWS_REGION:-us-east-1}

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
SCANS_DIR="$ROOT_DIR/scans"

echo "Collecting security evidence..."

mkdir -p "$SCANS_DIR"

# 1. Enable Inspector (if not already enabled)
echo "Ensuring Inspector is enabled..."
aws inspector2 enable --resource-types ECR --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null || true

# 2. Get ECR scan findings
echo "Fetching Inspector/ECR scan findings..."
aws ecr describe-image-scan-findings \
  --repository-name claim-api \
  --image-id imageTag=latest \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" > "$SCANS_DIR/inspector-findings.json" 2>/dev/null || {
  echo "⚠️  No scan findings yet. Trigger a new push or wait for scan completion."
}

# 3. Enable Security Hub (if not already enabled)
echo "Ensuring Security Hub is enabled..."
aws securityhub enable-security-hub --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null || true

# 4. Get Security Hub findings
echo "Fetching Security Hub findings..."
aws securityhub get-findings \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --max-results 50 > "$SCANS_DIR/security-hub-findings.json" 2>/dev/null || {
  echo "⚠️  No Security Hub findings available yet."
}

# 5. Summarize findings
echo ""
echo "✅ Security evidence collected in $SCANS_DIR"
echo ""

if [[ -f "$SCANS_DIR/inspector-findings.json" ]]; then
  CRITICAL=$(jq -r '.imageScanFindings.findingSeverityCounts.CRITICAL // 0' "$SCANS_DIR/inspector-findings.json" 2>/dev/null || echo "0")
  HIGH=$(jq -r '.imageScanFindings.findingSeverityCounts.HIGH // 0' "$SCANS_DIR/inspector-findings.json" 2>/dev/null || echo "0")
  MEDIUM=$(jq -r '.imageScanFindings.findingSeverityCounts.MEDIUM // 0' "$SCANS_DIR/inspector-findings.json" 2>/dev/null || echo "0")
  
  echo "Inspector Findings Summary:"
  echo "  Critical: $CRITICAL"
  echo "  High: $HIGH"
  echo "  Medium: $MEDIUM"
fi

echo ""
echo "Next steps:"
echo "1. Review findings in $SCANS_DIR"
echo "2. Add screenshots from AWS Console to screenshots/"
echo "3. Document remediation plan in scans/README.md"
