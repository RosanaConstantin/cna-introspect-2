# Infrastructure as Code (Terraform)

This folder scaffolds Terraform resources for:
- EKS cluster (EC2 worker nodes)
- VPC + subnets
- ECR repository
- DynamoDB table
- S3 bucket
- API Gateway
- IAM roles (IRSA)
- CodePipeline + CodeBuild
- Inspector + Security Hub enablement

Update values in [terraform/variables.tf](terraform/variables.tf) and run Terraform from the terraform directory.
