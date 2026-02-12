# Testing Guide & Evidence

## Smoke Tests

### 1) Health Check
```bash
curl https://<api-gateway-url>/claims/health
```

### 2) Get Claim Status
```bash
curl https://<api-gateway-url>/claims/CLM-1001
```

### 3) Summarize Claim Notes
```bash
curl -X POST https://<api-gateway-url>/claims/CLM-1001/summarize
```

## Expected Outputs
- `GET /claims/{id}` returns a DynamoDB item.
- `POST /claims/{id}/summarize` returns a JSON response with four summaries.

## Evidence
- Add API Gateway test screenshots to [SCREENSHOTS.md](SCREENSHOTS.md).
- Add CloudWatch log samples to [observability/queries.md](observability/queries.md).
