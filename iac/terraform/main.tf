resource "aws_dynamodb_table" "claims" {
  name         = var.claims_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_s3_bucket" "notes" {
  bucket = var.notes_bucket
}

resource "aws_ecr_repository" "claim_api" {
  name = var.ecr_repo
}

# Placeholder for EKS, VPC, API Gateway, IAM, CodePipeline, CodeBuild, Inspector, Security Hub.
# Add modules or resources based on your organization standards.
