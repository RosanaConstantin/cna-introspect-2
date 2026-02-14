# Deployment Guide

This guide documents a practical deployment path for the Claim Status API on EKS with API Gateway, DynamoDB, S3, Bedrock, CI/CD, and observability.

## Prerequisites
- AWS CLI v2
- kubectl
- eksctl
- Helm 3+
- Docker

## 1) Provision Infrastructure (IaC)
Use Terraform in [iac/terraform](iac/terraform). Update variables in [iac/terraform/variables.tf](iac/terraform/variables.tf).

```bash
terraform init
terraform plan
terraform apply
```

## 2) Build and Push Container
```bash
./scripts/build-and-push.sh
```

## 3) Deploy to EKS
```bash
./scripts/deploy.sh
```

## 3a) Seed Data (DynamoDB + S3)
```bash
./scripts/seed-data.sh
```

## 4) Configure API Gateway
Import [apigw/openapi.json](apigw/openapi.json) and set the backend integration to your EKS ingress/NLB URL.

## 5) Verify
```bash
./scripts/check-deployment.sh
```

## 6) Test Endpoints
```bash
./scripts/test.sh
```

## 7) (Optional) Set Up CI/CD Pipeline
For automated build and deployment:

```bash
./scripts/deploy-pipeline.sh
```

This creates:
- CodeBuild projects for build and deploy stages
- CodePipeline for orchestration
- S3 bucket for artifacts
- IAM roles with required permissions

See [pipelines/README.md](pipelines/README.md) for details.

**Note**: If you encounter permission issues, run:
```bash
./scripts/fix-pipeline-permissions.sh
```

## Cleanup
```bash
./scripts/cleanup.sh
```

---

## Deployment Scripts Summary


The following scripts are used throughout the deployment flow (including prerequisites and setup):

```bash
# Prerequisite and setup scripts
./scripts/setup-org-demo.sh         # Set up AWS profile and validate org-demo access
./scripts/setup-irsa.sh             # Set up IAM Roles for Service Accounts (IRSA) for EKS
./scripts/setup-apigw.sh            # Set up API Gateway for Claim API

# Main deployment flow
./scripts/build-and-push.sh         # Build and push Docker image
./scripts/deploy.sh                 # Deploy to EKS
./scripts/seed-data.sh              # Seed DynamoDB and S3
./scripts/check-deployment.sh       # Verify deployment
./scripts/test.sh                   # Test API endpoints
./scripts/test-apigw.sh             # Test API Gateway endpoints directly

# CI/CD Pipeline (optional)
./scripts/deploy-pipeline.sh        # Deploy CodePipeline and CodeBuild projects
./scripts/fix-pipeline-permissions.sh  # Fix IAM permissions for pipeline
./scripts/cleanup-pipeline.sh       # Remove pipeline resources

# Observability and Security
./scripts/collect-logs-evidence.sh  # Collect CloudWatch logs for evidence
./scripts/collect-security-evidence.sh  # Collect Inspector and Security Hub findings

# Cleanup
./scripts/cleanup.sh                # Cleanup EKS resources
```
