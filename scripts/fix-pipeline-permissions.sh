#!/bin/bash

# Fix CodeBuild IAM permissions for EKS deployment

set -e

export AWS_PROFILE=${AWS_PROFILE:-org-demo}
export AWS_REGION=${AWS_REGION:-us-east-1}

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Fixing CodeBuild IAM Permissions ===${NC}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
EKS_CLUSTER="claim-eks-cluster"
ARTIFACT_BUCKET="claim-api-artifacts-${ACCOUNT_ID}"

echo "Updating CodeBuildServiceRole inline policy..."

cat > /tmp/codebuild-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${AWS_REGION}:${ACCOUNT_ID}:log-group:/aws/codebuild/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${ARTIFACT_BUCKET}/*",
        "arn:aws:s3:::${ARTIFACT_BUCKET}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": "arn:aws:iam::${ACCOUNT_ID}:role/aws-service-role/eks.amazonaws.com/*"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name CodeBuildServiceRole \
    --policy-name CodeBuildBasePolicy \
    --policy-document file:///tmp/codebuild-policy.json

echo -e "${GREEN}IAM Policy updated successfully!${NC}"

# Update EKS aws-auth ConfigMap to allow CodeBuild role
echo -e "\n${YELLOW}Updating EKS aws-auth ConfigMap to allow CodeBuild role...${NC}"

CODEBUILD_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/CodeBuildServiceRole"
NODE_ROLE=$(kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapRoles}' | grep rolearn | head -1 | awk '{print $3}')

# Patch the configmap
kubectl patch configmap aws-auth -n kube-system --patch "$(cat <<EOF
data:
  mapRoles: |
    - rolearn: ${NODE_ROLE}
      groups:
      - system:bootstrappers
      - system:nodes
      username: system:node:{{EC2PrivateDNSName}}
    - rolearn: ${CODEBUILD_ROLE_ARN}
      username: codebuild
      groups:
      - system:masters
EOF
)"

echo -e "${GREEN}aws-auth ConfigMap updated!${NC}"

# Cleanup
rm -f /tmp/codebuild-policy.json

echo -e "\n${GREEN}=== Permissions Fixed ===${NC}"
echo ""
echo "You can now retry the pipeline execution:"
echo "  aws codepipeline start-pipeline-execution --name claim-api-pipeline"
echo ""
echo "Or from the console:"
echo "  https://console.aws.amazon.com/codesuite/codepipeline/pipelines/claim-api-pipeline/view"
