#!/bin/bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-claim-eks-cluster}
AWS_REGION=${AWS_REGION:-us-east-1}
AWS_PROFILE=${AWS_PROFILE:-org-demo}
NAMESPACE=${NAMESPACE:-default}
SERVICE_ACCOUNT_NAME=${SERVICE_ACCOUNT_NAME:-claim-api-sa}
ROLE_NAME=${ROLE_NAME:-ClaimApiIrsaRole}
POLICY_NAME=${POLICY_NAME:-ClaimApiIrsaPolicy}

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
SERVICEACCOUNT_FILE="$ROOT_DIR/k8s/claim-api-serviceaccount.yaml"

echo "Setting up IRSA for Claim API..."

echo "Using AWS Profile: $AWS_PROFILE"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text) || {
  echo "Error: Failed to get AWS Account ID from profile $AWS_PROFILE"
  exit 1
}

eksctl utils associate-iam-oidc-provider \
  --cluster "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --approve >/dev/null || true

OIDC_ISSUER=$(aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --query 'cluster.identity.oidc.issuer' \
  --output text)

if [[ -z "$OIDC_ISSUER" || "$OIDC_ISSUER" == "None" ]]; then
  echo "❌ OIDC issuer not found for cluster $CLUSTER_NAME"
  exit 1
fi

cat > claim-api-irsa-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "aws-marketplace:ViewSubscriptions",
        "aws-marketplace:Subscribe"
      ],
      "Resource": "*"
    }
  ]
}
EOF

POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
aws iam create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document file://claim-api-irsa-policy.json \
  --profile "$AWS_PROFILE" 2>/dev/null || {
  aws iam create-policy-version \
    --policy-arn "$POLICY_ARN" \
    --policy-document file://claim-api-irsa-policy.json \
    --set-as-default \
    --profile "$AWS_PROFILE"
}

OIDC_HOST=$(echo "$OIDC_ISSUER" | sed 's|https://||')

cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_HOST}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_HOST}:sub": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME}",
          "${OIDC_HOST}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file://trust-policy.json \
  --profile "$AWS_PROFILE" 2>/dev/null || {
  aws iam update-assume-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-document file://trust-policy.json \
    --profile "$AWS_PROFILE"
}

aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "$POLICY_ARN" \
  --profile "$AWS_PROFILE"

sed -i.bak "s|<IRSA_ROLE_ARN>|$ROLE_ARN|g" "$SERVICEACCOUNT_FILE"

rm -f claim-api-irsa-policy.json trust-policy.json

echo "✅ IRSA setup completed"
echo "Role ARN: $ROLE_ARN"
echo "Service Account: $SERVICE_ACCOUNT_NAME"
