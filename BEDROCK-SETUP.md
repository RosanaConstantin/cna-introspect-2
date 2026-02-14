# Bedrock Model Access Setup

## Issue
The application is failing with:
```
Model access is denied due to IAM user or service role is not authorized to perform the required AWS Marketplace actions
```

## Solution

### 1. Enable Model Access in AWS Console

1. Go to AWS Console → Amazon Bedrock
2. Click **Model access** in the left sidebar
3. Click **Manage model access** (orange button)
4. Find **Anthropic** section
5. Check the box for **Claude 3 Sonnet**
6. Click **Request model access** or **Save changes**

### 2. Wait for Access to Be Granted

- For some models, access is instant
- For Anthropic models, you may need to provide a use case and wait for approval
- Check the status in the Model access page

### 3. IAM Permissions (Already Fixed)

The IAM role has been updated with:
```json
{
  "Effect": "Allow",
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream",
    "aws-marketplace:ViewSubscriptions",
    "aws-marketplace:Subscribe"
  ],
  "Resource": "*"
}
```

### 4. Verify After Enabling

Once model access is granted:

```bash
# Restart pods to ensure fresh credentials
kubectl rollout restart deployment claim-api

# Wait for pods to be ready
kubectl get pods -l app=claim-api

# Test the summarization endpoint
curl -X POST https://i21ffci3hk.execute-api.us-east-1.amazonaws.com/prod/claims/CLM-1001/summarize
```

### 5. Check Logs

```bash
kubectl logs -l app=claim-api --tail=50 | grep -i bedrock
```

If successful, you should NOT see "Bedrock invocation failed" messages.

## Alternative: Use Mock Data for Demo

If Bedrock access is not immediately available, the application automatically falls back to mock summaries. The mock responses provide realistic-looking summaries that demonstrate the API functionality while model access is being provisioned.
