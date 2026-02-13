# CloudWatch Logs Insights Queries

## 1) Error Rate by Endpoint
```
fields @timestamp, @message
| filter @message like /error|Exception|500/
| stats count() as errors by bin(5m)
```

## 2) Latency by Endpoint
```
fields @timestamp, @message
| filter @message like /duration/
| stats avg(duration_ms) as avg_latency by bin(5m)
```

## 3) Summarization Requests
```
fields @timestamp, @message
| filter @message like /summarize/
| stats count() as summarize_calls by bin(10m)
```

## Evidence
- Document query results and findings in your validation process
- Record query timestamps and log group names
