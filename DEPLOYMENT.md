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

## Cleanup
```bash
./scripts/cleanup.sh
```
