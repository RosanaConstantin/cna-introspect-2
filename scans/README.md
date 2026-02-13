# Security Scan Evidence (Local Only)

This directory contains security scan results from AWS Inspector and Security Hub collected locally for validation purposes.

## Files (Git-Ignored for Security)

- `inspector-findings.json` - ECR image vulnerability scan results
- `security-hub-findings.json` - AWS Security Hub compliance findings

## Why Files Are Git-Ignored

These JSON files contain sensitive metadata about the AWS environment and should never be committed to a public repository. They are generated locally for:

- Validation during development
- Understanding security posture
- Documenting findings in assessment reports

Anyone with read access to a public repository can see exposed secrets and infrastructure details from these files.

## Collecting Evidence Locally

To generate evidence files for your validation:

```bash
sh scripts/collect-security-evidence.sh
```

This will:
1. Query AWS Inspector for ECR image scan findings
2. Query Security Hub for compliance findings
3. Write JSON results to this directory (local only)

## Local Validation Checklist

When validating the deployment locally:

- [ ] Review `inspector-findings.json` for container vulnerabilities
- [ ] Review `security-hub-findings.json` for compliance gaps
- [ ] Document top 3 findings and remediation steps
- [ ] Record scan timestamps and image digests
- [ ] **DO NOT commit these files**

## For Production

In a production environment:

- Forward findings to a centralized SIEM or security team
- Implement automated remediation through AWS Config
- Use SNS topics to trigger alert workflows
- Archive findings to S3 (with encryption) for compliance auditing
- Configure Security Hub to aggregate findings across regions

## Security Best Practices

✅ **DO**:
- Review findings locally before committing code
- Document findings in your assessment report
- Implement remediation before production deployment
- Archive scan results securely separate from source code

❌ **DO NOT**:
- Commit scan results to version control
- Share JSON files with sensitive account/resource information
- Expose Security Hub findings in public repositories
- Store AWS credentials anywhere in the repository
