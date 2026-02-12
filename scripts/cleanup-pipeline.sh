#!/bin/bash

# Cleanup CodePipeline resources
# Use this script to remove all pipeline-related resources

set -e

export AWS_PROFILE=${AWS_PROFILE:-org-demo}
export AWS_REGION=${AWS_REGION:-us-east-1}

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Cleaning up CI/CD Pipeline Resources ===${NC}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PIPELINE_NAME="claim-api-pipeline"
BUILD_PROJECT="claim-api-build"
DEPLOY_PROJECT="claim-api-deploy"
ARTIFACT_BUCKET="claim-api-artifacts-${ACCOUNT_ID}"

# Delete pipeline
echo -e "\n${YELLOW}Deleting CodePipeline...${NC}"
if aws codepipeline get-pipeline --name "${PIPELINE_NAME}" 2>/dev/null; then
    aws codepipeline delete-pipeline --name "${PIPELINE_NAME}"
    echo "Pipeline deleted: ${PIPELINE_NAME}"
else
    echo "Pipeline not found"
fi

# Delete CodeBuild projects
echo -e "\n${YELLOW}Deleting CodeBuild projects...${NC}"
for PROJECT in "${BUILD_PROJECT}" "${DEPLOY_PROJECT}"; do
    if aws codebuild batch-get-projects --names "${PROJECT}" --query 'projects[0].name' --output text 2>/dev/null | grep -q "${PROJECT}"; then
        aws codebuild delete-project --name "${PROJECT}"
        echo "Project deleted: ${PROJECT}"
    else
        echo "Project not found: ${PROJECT}"
    fi
done

# Empty and delete S3 bucket
echo -e "\n${YELLOW}Cleaning up S3 artifact bucket...${NC}"
if aws s3 ls "s3://${ARTIFACT_BUCKET}" 2>/dev/null; then
    aws s3 rm "s3://${ARTIFACT_BUCKET}" --recursive
    aws s3 rb "s3://${ARTIFACT_BUCKET}"
    echo "Bucket deleted: ${ARTIFACT_BUCKET}"
else
    echo "Bucket not found"
fi

# Note: IAM roles are left intact as they may be reused
echo -e "\n${GREEN}Cleanup complete!${NC}"
echo ""
echo "Note: IAM roles CodeBuildServiceRole and CodePipelineServiceRole were not deleted."
echo "To delete them manually:"
echo "  aws iam delete-role-policy --role-name CodeBuildServiceRole --policy-name CodeBuildBasePolicy"
echo "  aws iam detach-role-policy --role-name CodeBuildServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
echo "  aws iam detach-role-policy --role-name CodeBuildServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
echo "  aws iam delete-role --role-name CodeBuildServiceRole"
echo ""
echo "  aws iam delete-role-policy --role-name CodePipelineServiceRole --policy-name CodePipelineBasePolicy"
echo "  aws iam delete-role --role-name CodePipelineServiceRole"
