# GenAI-enabled Claim Status API (EKS + API Gateway)

[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![API Gateway](https://img.shields.io/badge/AWS-API%20Gateway-purple)](https://aws.amazon.com/api-gateway/)
[![Bedrock](https://img.shields.io/badge/AWS-Bedrock-blue)](https://aws.amazon.com/bedrock/)

This repository implements Introspect 2B: a GenAI-enabled Claim Status API deployed on Amazon EKS (EC2 worker nodes) and exposed via Amazon API Gateway. It includes infrastructure-as-code, CI/CD automation, security/observability artifacts, and documentation.

## Architecture (High-Level)

```
API Gateway → NLB/Ingress → Claim API (EKS)
  ├─ DynamoDB (claim status)
  ├─ S3 (claim notes)
  └─ Bedrock (summaries + recommendations)
```

See [architecture-diagram.md](architecture-diagram.md) for a detailed flow and component responsibilities.

## Objectives Mapping
- EKS with EC2 worker nodes
- API Gateway REST endpoints for Claim API
- Bedrock integration for summarization and next-step recommendation
- CI/CD with CodePipeline + CodeBuild
- Security scanning with Inspector + Security Hub
- Observability via CloudWatch Logs/metrics

## Project Structure

```
cna-introspect-2/
├── README.md
├── DEPLOYMENT.md
├── TESTING.md
├── SCREENSHOTS.md
├── PROJECT-COMPLETION.md
├── architecture-diagram.md
├── bedrock-insights.md
├── src/
│   └── claim-api/
│       ├── Dockerfile
│       ├── package.json
│       └── server.js
├── mocks/
│   ├── claims.json
│   └── notes.json
├── apigw/
│   ├── README.md
│   └── openapi.json
├── iac/
│   ├── README.md
│   └── terraform/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── pipelines/
│   ├── README.md
│   ├── buildspec-build.yml
│   ├── buildspec-deploy.yml
│   └── codepipeline.yaml
├── k8s/
│   ├── claim-api-deployment.yaml
│   ├── claim-api-service.yaml
│   └── hpa.yaml
├── infrastructure/
│   └── eks-cluster.yaml
├── observability/
│   └── queries.md
├── scans/
│   └── README.md
└── scripts/
    ├── build-and-push.sh
    ├── deploy.sh
    ├── test.sh
    ├── check-deployment.sh
    └── cleanup.sh
```

## API Endpoints

- `GET /claims/{id}`
  - Retrieves claim status from DynamoDB.
- `POST /claims/{id}/summarize`
  - Reads claim notes from S3.
  - Invokes Amazon Bedrock to generate:
    - Overall summary
    - Customer-facing summary
    - Adjuster-focused summary
    - Recommended next step

## Quick Start (High-Level)
1. Provision infra from [iac/README.md](iac/README.md).
2. Build/push container via [scripts/build-and-push.sh](scripts/build-and-push.sh).
3. Deploy to EKS via [scripts/deploy.sh](scripts/deploy.sh).
4. Configure API Gateway with [apigw/openapi.json](apigw/openapi.json).
5. Run smoke tests from [TESTING.md](TESTING.md).

## GenAI Prompts Used (Summary)
- “Summarize the claim notes in 5 bullet points.”
- “Write a customer-facing summary with empathetic tone.”
- “Provide adjuster-facing summary with key risk factors.”
- “Recommend the next best action in one sentence.”

Full prompt templates are in [bedrock-insights.md](bedrock-insights.md).

## Notes
- Use EC2 worker nodes (no Fargate).
- Replace placeholders for ARNs, account IDs, and endpoints.
- Add screenshots/links as you validate components.

## License
Educational use only for Cloud Native Application certification.
