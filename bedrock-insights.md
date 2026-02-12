# Bedrock Insights

## Prompt Templates

### Overall Summary
"Summarize the following claim notes in 5 concise bullet points. Focus on incident facts, timestamps, and severity. Notes: {{notes}}"

### Customer-Facing Summary
"Write a customer-facing summary using empathetic tone and plain language (2-4 sentences). Notes: {{notes}}"

### Adjuster Summary
"Provide an adjuster-focused summary highlighting risk factors, coverage concerns, and missing information. Notes: {{notes}}"

### Recommended Next Step
"Suggest the next best action in one sentence, prioritizing risk mitigation and required documentation. Notes: {{notes}}"

## Model Selection Considerations
- Use a text model with deterministic output (low temperature)
- Enforce JSON schema response for downstream processing

## Safety + Compliance
- Avoid PII leakage by redacting sensitive fields before summarization
- Maintain prompt logs for auditability

## Outputs Schema (Recommended)
```json
{
  "overall": "...",
  "customer": "...",
  "adjuster": "...",
  "nextStep": "..."
}
```
