# CI/CD Pipelines

This folder contains CodeBuild buildspecs and CodePipeline definition for automated build and deployment.

## Files

- **buildspec-build.yml**: Build and push Docker image to ECR
- **buildspec-deploy.yml**: Deploy Kubernetes manifests to EKS
- **codepipeline.yaml**: Sample pipeline stages (Source → Build → Deploy)

## Quick Start

### Deploy Pipeline

```bash
# From project root
./scripts/deploy-pipeline.sh
```

This creates:
- **CodeBuild Projects**: `claim-api-build` and `claim-api-deploy`
- **CodePipeline**: `claim-api-pipeline`
- **S3 Bucket**: For pipeline artifacts
- **IAM Roles**: With required permissions

### Fix Permissions (if needed)

```bash
./scripts/fix-pipeline-permissions.sh
```

### Cleanup Pipeline

```bash
./scripts/cleanup-pipeline.sh
```

## Pipeline Stages

### 1. Source
- S3-based source (for demonstration)
- Can be replaced with GitHub/CodeCommit integration

### 2. Build
- Uses `buildspec-build.yml`
- Builds Docker image from `src/claim-api`
- Pushes to ECR
- Outputs k8s manifests as artifacts

### 3. Deploy
- Uses `buildspec-deploy.yml`
- Updates kubeconfig for EKS cluster
- Applies Kubernetes manifests

## Environment Variables

Build and deploy stages use these environment variables:

- `AWS_REGION`: AWS region (default: us-east-1)
- `ACCOUNT_ID`: AWS account ID
- `ECR_REPO`: ECR repository name (default: claim-api)
- `EKS_CLUSTER`: EKS cluster name (default: claim-eks-cluster)

## Manual Trigger

```bash
aws codepipeline start-pipeline-execution \
  --name claim-api-pipeline \
  --region us-east-1 \
  --profile org-demo
```

## Monitor Pipeline

View in AWS Console:
```
https://console.aws.amazon.com/codesuite/codepipeline/pipelines/claim-api-pipeline/view
```

Or check status:
```bash
aws codepipeline get-pipeline-state \
  --name claim-api-pipeline \
  --region us-east-1 \
  --profile org-demo
```

## Status

✅ **Pipeline is fully operational!**

All three stages (Source → Build → Deploy) are working successfully.

See [../PIPELINE-TROUBLESHOOTING.md](../PIPELINE-TROUBLESHOOTING.md) for complete troubleshooting history and resolution details.

## Notes

- Pipeline demonstrates complete CI/CD automation
- Manual deployment scripts in [../scripts/](../scripts/) also available
- S3 bucket versioning is required and enabled
- All IAM permissions configured correctly

