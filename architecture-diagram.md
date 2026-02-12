# Architecture Diagram (Text)

```
Client
  ↓
API Gateway (REST)
  ↓
NLB/Ingress
  ↓
EKS (Claim API)
  ├─ DynamoDB: claim status
  ├─ S3: claim notes
  └─ Bedrock: summarization + recommendation
```

## Data Flow
1. `GET /claims/{id}` → Claim API → DynamoDB → response.
2. `POST /claims/{id}/summarize` → Claim API → S3 (notes) → Bedrock → response.

## Security + Observability
- IAM roles for service accounts (IRSA)
- CloudWatch Logs + Metrics
- Inspector scans + Security Hub aggregation
