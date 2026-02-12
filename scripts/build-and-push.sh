#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE=${AWS_PROFILE:-org-demo}
REGION=${AWS_REGION:-us-east-1}
ECR_REPO=${ECR_REPO:-claim-api}

ACCOUNT_ID=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)

aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$REGION" --profile "$AWS_PROFILE" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "$ECR_REPO" --region "$REGION" --profile "$AWS_PROFILE"

aws ecr get-login-password --region "$REGION" --profile "$AWS_PROFILE" | \
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

docker build --platform linux/amd64 -t "$ECR_REPO:latest" src/claim-api

docker tag "$ECR_REPO:latest" "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest"

docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest"

sed -i.bak "s|<ACCOUNT_ID>|$ACCOUNT_ID|g" k8s/claim-api-deployment.yaml
sed -i.bak "s|<REGION>|$REGION|g" k8s/claim-api-deployment.yaml
