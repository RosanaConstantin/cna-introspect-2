## Sample Test Output

### API Gateway Tests (actual output from 2026-02-14)

```bash
$ curl -X POST https://i21ffci3hk.execute-api.us-east-1.amazonaws.com/prod/claims/CLM-1001/summarize
{
  "id": "CLM-1001",
  "overall": "- Minor collision reported.\n- Police report filed.\n- Vehicle is drivable.\n- Photos of the incident have been uploaded.\n- Further details may be required for claim processing.",
  "customer": "We understand that being involved in a collision can be stressful, but we're here to support you through the process. Based on the information provided, it appears that a minor collision occurred, and a police report was filed. Fortunately, your vehicle is still drivable, and you've uploaded photos of the incident.",
  "adjuster": "While a minor collision has been reported, and a police report and photos have been provided, there may be additional information needed to fully assess the risks and determine the appropriate course of action. Details regarding the extent of damage, potential injuries, and any other relevant factors should be gathered.",
  "nextStep": "The next step would be to schedule an inspection of the vehicle to assess the extent of the damage and determine the appropriate repairs or compensation."
}
```

### Bedrock Integration Verification

Multiple requests to the same endpoint produce varied responses, confirming real-time AI generation:

```bash
Test 1: "The next step should be to schedule an in-person inspection of the vehicle..."
Test 2: "The next step should be to schedule an in-person or virtual vehicle inspection..."
Test 3: "The next step would be to schedule an inspection of the vehicle..."
```

✅ **Bedrock Status**: Working successfully with Anthropic Claude 3 Sonnet model

### Direct EKS Tests

```bash
$ curl http://a1ce8c0d6c1c94351901a87b2b4dab84-1210982105.us-east-1.elb.amazonaws.com/claims/health
{"status":"ok"}

$ curl http://a1ce8c0d6c1c94351901a87b2b4dab84-1210982105.us-east-1.elb.amazonaws.com/claims/CLM-1001
{"id":"CLM-1001","status":"OPEN","policyId":"POL-9001","lossDate":"2024-11-02","amount":5200}
```

## Log Evidence

### Application Logs (kubectl logs)

```
> claim-api@1.0.0 start
> node server.js

Claim API listening on port 3000
```

No Bedrock errors after IAM policy update and pod restart.
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
- Add CloudWatch log samples to [observability/queries.md](observability/queries.md).
