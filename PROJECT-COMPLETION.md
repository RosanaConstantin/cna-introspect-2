# Project Completion Checklist (Introspect 2B)

## Core Requirements
- [ ] EKS cluster running with EC2 worker nodes
- [ ] Claim API deployed on EKS
- [ ] API Gateway routes configured and validated
- [ ] DynamoDB table for claim status
- [ ] S3 bucket for claim notes
- [ ] Amazon Bedrock integrated for summarization
- [ ] CI/CD pipeline (CodePipeline + CodeBuild)
- [ ] Image scanning (Inspector) + Security Hub findings
- [ ] Observability with CloudWatch logs/metrics

## Functional Validation
- [ ] GET /claims/{id} returns DynamoDB item
- [ ] POST /claims/{id}/summarize returns 4-part summary
- [ ] Bedrock model access approved and validated

## Evidence Checklist
- [ ] API Gateway invocation screenshot
- [ ] CloudWatch Logs Insights queries saved
- [ ] Inspector findings captured
- [ ] Security Hub overview screenshot
- [ ] Architecture rationale documented
- [ ] CI/CD pipeline run evidence (build + deploy)
- [ ] EKS node group screenshot

## Notes
Record trade-offs, constraints, and decisions in README.
