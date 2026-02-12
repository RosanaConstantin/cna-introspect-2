#!/bin/bash

# Deploy CodePipeline for Claim API
# This script creates CodeBuild projects and CodePipeline for CI/CD evidence

set -e

# Set AWS profile
export AWS_PROFILE=${AWS_PROFILE:-org-demo}
export AWS_REGION=${AWS_REGION:-us-east-1}

# Get project root directory
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Deploying CI/CD Pipeline ===${NC}"

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"

# Variables
EKS_CLUSTER="claim-eks-cluster"
ECR_REPO="claim-api"
PIPELINE_NAME="claim-api-pipeline"
BUILD_PROJECT="claim-api-build"
DEPLOY_PROJECT="claim-api-deploy"
ARTIFACT_BUCKET="claim-api-artifacts-${ACCOUNT_ID}"

# Step 1: Create S3 bucket for artifacts
echo -e "\n${YELLOW}Step 1: Creating S3 artifact bucket...${NC}"
if aws s3 ls "s3://${ARTIFACT_BUCKET}" 2>/dev/null; then
    echo "Bucket already exists"
else
    aws s3 mb "s3://${ARTIFACT_BUCKET}" --region $AWS_REGION
    echo "Bucket created: ${ARTIFACT_BUCKET}"
fi

# Step 2: Create IAM role for CodeBuild
echo -e "\n${YELLOW}Step 2: Creating IAM role for CodeBuild...${NC}"

# Trust policy
cat > /tmp/codebuild-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Check if role exists
if aws iam get-role --role-name CodeBuildServiceRole 2>/dev/null; then
    echo "Role already exists"
else
    aws iam create-role \
        --role-name CodeBuildServiceRole \
        --assume-role-policy-document file:///tmp/codebuild-trust-policy.json
    
    # Attach managed policies
    aws iam attach-role-policy \
        --role-name CodeBuildServiceRole \
        --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
    
    aws iam attach-role-policy \
        --role-name CodeBuildServiceRole \
        --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
    
    # Create inline policy for CloudWatch Logs, S3, and EKS
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
    
    echo "Role created: CodeBuildServiceRole"
    sleep 10  # Wait for role propagation
fi

# Step 3: Create IAM role for CodePipeline
echo -e "\n${YELLOW}Step 3: Creating IAM role for CodePipeline...${NC}"

# Trust policy
cat > /tmp/codepipeline-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

if aws iam get-role --role-name CodePipelineServiceRole 2>/dev/null; then
    echo "Role already exists"
else
    aws iam create-role \
        --role-name CodePipelineServiceRole \
        --assume-role-policy-document file:///tmp/codepipeline-trust-policy.json
    
    # Create inline policy
    cat > /tmp/codepipeline-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::${ARTIFACT_BUCKET}/*",
        "arn:aws:s3:::${ARTIFACT_BUCKET}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": [
        "arn:aws:codebuild:${AWS_REGION}:${ACCOUNT_ID}:project/${BUILD_PROJECT}",
        "arn:aws:codebuild:${AWS_REGION}:${ACCOUNT_ID}:project/${DEPLOY_PROJECT}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "*"
    }
  ]
}
EOF
    
    aws iam put-role-policy \
        --role-name CodePipelineServiceRole \
        --policy-name CodePipelineBasePolicy \
        --policy-document file:///tmp/codepipeline-policy.json
    
    echo "Role created: CodePipelineServiceRole"
    sleep 10
fi

# Step 4: Create CodeBuild project for Build stage
echo -e "\n${YELLOW}Step 4: Creating CodeBuild project for Build...${NC}"

cat > /tmp/build-project.json <<EOF
{
  "name": "${BUILD_PROJECT}",
  "description": "Build and push Docker image for Claim API",
  "source": {
    "type": "CODEPIPELINE",
    "buildspec": "pipelines/buildspec-build.yml"
  },
  "artifacts": {
    "type": "CODEPIPELINE"
  },
  "environment": {
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/standard:7.0",
    "computeType": "BUILD_GENERAL1_SMALL",
    "privilegedMode": true,
    "environmentVariables": [
      {
        "name": "AWS_REGION",
        "value": "${AWS_REGION}",
        "type": "PLAINTEXT"
      },
      {
        "name": "ACCOUNT_ID",
        "value": "${ACCOUNT_ID}",
        "type": "PLAINTEXT"
      },
      {
        "name": "ECR_REPO",
        "value": "${ECR_REPO}",
        "type": "PLAINTEXT"
      }
    ]
  },
  "serviceRole": "arn:aws:iam::${ACCOUNT_ID}:role/CodeBuildServiceRole"
}
EOF

if aws codebuild batch-get-projects --names "${BUILD_PROJECT}" --query 'projects[0].name' --output text 2>/dev/null | grep -q "${BUILD_PROJECT}"; then
    echo "Build project already exists, updating..."
    aws codebuild update-project --cli-input-json file:///tmp/build-project.json
else
    aws codebuild create-project --cli-input-json file:///tmp/build-project.json
    echo "Build project created: ${BUILD_PROJECT}"
fi

# Step 5: Create CodeBuild project for Deploy stage
echo -e "\n${YELLOW}Step 5: Creating CodeBuild project for Deploy...${NC}"

cat > /tmp/deploy-project.json <<EOF
{
  "name": "${DEPLOY_PROJECT}",
  "description": "Deploy Claim API to EKS",
  "source": {
    "type": "CODEPIPELINE",
    "buildspec": "pipelines/buildspec-deploy.yml"
  },
  "artifacts": {
    "type": "CODEPIPELINE"
  },
  "environment": {
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/standard:7.0",
    "computeType": "BUILD_GENERAL1_SMALL",
    "privilegedMode": false,
    "environmentVariables": [
      {
        "name": "AWS_REGION",
        "value": "${AWS_REGION}",
        "type": "PLAINTEXT"
      },
      {
        "name": "EKS_CLUSTER",
        "value": "${EKS_CLUSTER}",
        "type": "PLAINTEXT"
      }
    ]
  },
  "serviceRole": "arn:aws:iam::${ACCOUNT_ID}:role/CodeBuildServiceRole"
}
EOF

if aws codebuild batch-get-projects --names "${DEPLOY_PROJECT}" --query 'projects[0].name' --output text 2>/dev/null | grep -q "${DEPLOY_PROJECT}"; then
    echo "Deploy project already exists, updating..."
    aws codebuild update-project --cli-input-json file:///tmp/deploy-project.json
else
    aws codebuild create-project --cli-input-json file:///tmp/deploy-project.json
    echo "Deploy project created: ${DEPLOY_PROJECT}"
fi

# Step 6: Create CodePipeline (without source for now - manual trigger)
echo -e "\n${YELLOW}Step 6: Creating CodePipeline...${NC}"

cat > /tmp/pipeline.json <<EOF
{
  "pipeline": {
    "name": "${PIPELINE_NAME}",
    "roleArn": "arn:aws:iam::${ACCOUNT_ID}:role/CodePipelineServiceRole",
    "artifactStore": {
      "type": "S3",
      "location": "${ARTIFACT_BUCKET}"
    },
    "stages": [
      {
        "name": "Source",
        "actions": [
          {
            "name": "SourceAction",
            "actionTypeId": {
              "category": "Source",
              "owner": "AWS",
              "provider": "S3",
              "version": "1"
            },
            "outputArtifacts": [
              {
                "name": "SourceOutput"
              }
            ],
            "configuration": {
              "S3Bucket": "${ARTIFACT_BUCKET}",
              "S3ObjectKey": "source.zip",
              "PollForSourceChanges": "false"
            }
          }
        ]
      },
      {
        "name": "Build",
        "actions": [
          {
            "name": "BuildAction",
            "actionTypeId": {
              "category": "Build",
              "owner": "AWS",
              "provider": "CodeBuild",
              "version": "1"
            },
            "inputArtifacts": [
              {
                "name": "SourceOutput"
              }
            ],
            "outputArtifacts": [
              {
                "name": "BuildOutput"
              }
            ],
            "configuration": {
              "ProjectName": "${BUILD_PROJECT}"
            }
          }
        ]
      },
      {
        "name": "Deploy",
        "actions": [
          {
            "name": "DeployAction",
            "actionTypeId": {
              "category": "Build",
              "owner": "AWS",
              "provider": "CodeBuild",
              "version": "1"
            },
            "inputArtifacts": [
              {
                "name": "BuildOutput"
              }
            ],
            "configuration": {
              "ProjectName": "${DEPLOY_PROJECT}"
            }
          }
        ]
      }
    ]
  }
}
EOF

if aws codepipeline get-pipeline --name "${PIPELINE_NAME}" 2>/dev/null; then
    echo "Pipeline already exists, updating..."
    aws codepipeline update-pipeline --cli-input-json file:///tmp/pipeline.json
else
    aws codepipeline create-pipeline --cli-input-json file:///tmp/pipeline.json
    echo "Pipeline created: ${PIPELINE_NAME}"
fi

# Step 7: Package source code and upload to S3
echo -e "\n${YELLOW}Step 7: Packaging source code...${NC}"
cd "$ROOT_DIR"
zip -r /tmp/source.zip . \
    -x "*.git*" \
    -x "*node_modules*" \
    -x "*.DS_Store" \
    -x "*scans/*" \
    -x "*.zip"

aws s3 cp /tmp/source.zip "s3://${ARTIFACT_BUCKET}/source.zip"
echo "Source uploaded to S3"

# Step 8: Trigger pipeline execution
echo -e "\n${YELLOW}Step 8: Starting pipeline execution...${NC}"
EXECUTION_ID=$(aws codepipeline start-pipeline-execution \
    --name "${PIPELINE_NAME}" \
    --query 'pipelineExecutionId' \
    --output text)

echo -e "${GREEN}Pipeline execution started: ${EXECUTION_ID}${NC}"

# Cleanup temp files
rm -f /tmp/codebuild-trust-policy.json
rm -f /tmp/codebuild-policy.json
rm -f /tmp/codepipeline-trust-policy.json
rm -f /tmp/codepipeline-policy.json
rm -f /tmp/build-project.json
rm -f /tmp/deploy-project.json
rm -f /tmp/pipeline.json
rm -f /tmp/source.zip

echo -e "\n${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "Pipeline Name: ${PIPELINE_NAME}"
echo "Build Project: ${BUILD_PROJECT}"
echo "Deploy Project: ${DEPLOY_PROJECT}"
echo "Artifact Bucket: ${ARTIFACT_BUCKET}"
echo ""
echo "View pipeline: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${PIPELINE_NAME}/view"
echo ""
echo "Monitor execution with:"
echo "  aws codepipeline get-pipeline-state --name ${PIPELINE_NAME}"
