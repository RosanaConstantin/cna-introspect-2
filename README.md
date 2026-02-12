# GenAI-enabled Claim Status API (EKS + API Gateway)

[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![API Gateway](https://img.shields.io/badge/AWS-API%20Gateway-purple)](https://aws.amazon.com/api-gateway/)
[![Bedrock](https://img.shields.io/badge/AWS-Bedrock-blue)](https://aws.amazon.com/bedrock/)

This repository implements Introspect 2B: a GenAI-enabled Claim Status API deployed on Amazon EKS (EC2 worker nodes) and exposed via Amazon API Gateway. It includes infrastructure-as-code, CI/CD automation, security/observability artifacts, and documentation.

> **Note on Bedrock Model Access**: Serverless foundation models are automatically enabled when first invoked. For Anthropic models, first-time users must submit use case details at first invocation. The API includes automatic fallback to mock summaries if Bedrock access is not yet available.

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

## Architecture & Design Rationale
- **EKS on EC2**: satisfies enterprise constraints and avoids Fargate.
- **API Gateway + NLB/Ingress**: decouples public API lifecycle from cluster services.
- **DynamoDB + S3**: separates structured claim status from unstructured notes.
- **Bedrock**: summaries and recommendations are generated on demand for each claim.

## Trade-offs
- **API Gateway proxy** simplifies exposure, but adds cost/latency vs direct NLB access.
- **PAY_PER_REQUEST DynamoDB** reduces ops overhead but may cost more at scale.
- **S3 per-claim notes** improves auditability but requires object naming conventions.

## Modernization Strategy
- Start with a containerized API on EKS.
- Isolate GenAI interaction behind a single endpoint.
- Gradually split into microservices (claims, notes, summarization) once traffic grows.

## Security & Compliance
- **IRSA** for pod-to-AWS access (no static credentials).
- **Inspector** for container scan and **Security Hub** for centralized findings.
- **S3/DynamoDB** access scoped to least privilege (documented in IRSA policy).

## Scalability & Resilience
- **HPA** for API pods.
- Multi-AZ worker nodes in EKS.
- Stateless API design; data in DynamoDB/S3.

## Observability
- CloudWatch Logs for application logs.
- Logs Insights queries in [observability/queries.md](observability/queries.md).
- Add screenshots in [SCREENSHOTS.md](SCREENSHOTS.md).

## CI/CD
- CodeBuild build spec: [pipelines/buildspec-build.yml](pipelines/buildspec-build.yml)
- CodeBuild deploy spec: [pipelines/buildspec-deploy.yml](pipelines/buildspec-deploy.yml)
- Pipeline skeleton: [pipelines/codepipeline.yaml](pipelines/codepipeline.yaml)

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

## Evidence & Screenshots
- [SCREENSHOTS.md](SCREENSHOTS.md)
- [scans/README.md](scans/README.md)

## Future Roadmap
- Add request validation + schema enforcement.
- Add rate limiting and WAF protection at API Gateway.
- Implement blue/green deployments in CodePipeline.
- Add caching for frequent summary requests.

## License
Educational use only for Cloud Native Application certification.
