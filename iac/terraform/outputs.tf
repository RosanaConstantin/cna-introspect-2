output "claims_table" {
  value = aws_dynamodb_table.claims.name
}

output "notes_bucket" {
  value = aws_s3_bucket.notes.bucket
}

output "ecr_repo" {
  value = aws_ecr_repository.claim_api.name
}
