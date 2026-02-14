# Pipeline Troubleshooting & Resolution

## Executive Summary

**Status**: ✅ **FULLY OPERATIONAL**

The CI/CD pipeline for the claim-api project is now fully functional with all three stages (Source → Build → Deploy) executing successfully.

**Pipeline Execution ID**: `84eeba59-6b19-4a92-8b36-8dfffe5a6706`

## Final Pipeline Status

```
-------------------------
|   GetPipelineState    |
+---------+-------------+
|  Source |  Succeeded  |
|  Build  |  Succeeded  |
|  Deploy |  Succeeded  |
+---------+-------------+
```

## Issues Encountered & Resolutions

### Issue 1: Source Stage Permission Error

**Symptom**: 
```
"code": "PermissionError"
"message": "The provided role does not have permissions to perform this action."
```

**Root Cause**: 
- S3 bucket did not have versioning enabled
- CodePipeline S3 source actions require bucket versioning
- Missing `s3:GetBucketVersioning` permission

**Resolution**:
1. Enabled S3 bucket versioning:
   ```bash
   aws s3api put-bucket-versioning \
     --bucket claim-api-artifacts-335444506576 \
     --versioning-configuration Status=Enabled
   ```

2. Added `s3:GetBucketVersioning` to CodePipelineServiceRole IAM policy

3. Reuploaded source.zip to get a version ID

**Verification**:
- S3 object now has version ID: `FPoRxgkQf3Qq46UJhYcpsCfHRfE5MBQo`
- Source stage: ✅ Succeeded

### Issue 2: Build Stage ECR Login Failure

**Symptom**:
```
/codebuild/output/tmp/script.sh: 4: Login: not found
exit status 127
```

**Root Cause**: 
Incorrect command syntax in [buildspec-build.yml](pipelines/buildspec-build.yml):
```yaml
# WRONG:
- $(aws ecr get-login-password --region $AWS_REGION | docker login ...)
```

The `$()` command substitution was trying to execute the output "Login Succeeded" as a command.

**Resolution**:
Removed the `$()` wrapper:
```yaml
# CORRECT:
- aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

**Verification**:
- Docker login succeeded
- Image build completed
- Image push to ECR succeeded
- Build stage: ✅ Succeeded

### Issue 3: Deploy Stage Buildspec Not Found

**Symptom**:
```
stat /codebuild/output/src.../pipelines/buildspec-deploy.yml: no such file or directory
```

**Root Cause**: 
Build stage artifacts only included `k8s/**` but the Deploy stage needed `buildspec-deploy.yml`

**Resolution**:
Updated [buildspec-build.yml](pipelines/buildspec-build.yml) artifacts section:
```yaml
artifacts:
  files:
    - k8s/**
    - pipelines/buildspec-deploy.yml  # Added
```

**Verification**:
- Deploy buildspec found in artifacts
- EKS kubectl commands executed
- Kubernetes manifests applied
- Deploy stage: ✅ Succeeded

## Technical Details

### Pipeline Configuration

**Pipeline Name**: `claim-api-pipeline`
**Region**: `us-east-1`
**Account**: `335444506576`

**Stages**:
1. **Source**: S3 bucket with versioning
   - Bucket: `claim-api-artifacts-335444506576`
   - Object: `source.zip`
   - Version ID: Auto-tracked by S3 versioning

2. **Build**: Docker image build and push
   - Project: `claim-api-build`
   - Buildspec: `pipelines/buildspec-build.yml`
   - ECR Repository: `claim-api`
   - Image Tag: `latest`

3. **Deploy**: Kubernetes deployment to EKS
   - Project: `claim-api-deploy`
   - Buildspec: `pipelines/buildspec-deploy.yml`
   - EKS Cluster: `claim-eks-cluster`
   - Namespace: `default`

### IAM Permissions Required

**CodePipelineServiceRole**:
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:GetObjectVersion",
    "s3:GetBucketVersioning",
    "s3:PutObject",
    "s3:ListBucket",
    "s3:GetBucketLocation",
    "codebuild:BatchGetBuilds",
    "codebuild:StartBuild"
  ],
  "Resource": "*"
}
```

**CodeBuildServiceRole**:
- ECR push permissions
- EKS cluster access
- CloudWatch Logs access

**ClaimApiIrsaRole** (for pods):
- DynamoDB access
- S3 access
- Bedrock access
- AWS Marketplace permissions

### S3 Versioning Verification

```bash
aws s3api list-object-versions \
  --bucket claim-api-artifacts-335444506576 \
  --prefix source.zip
```

Output:
```
source.zip | FPoRxgkQf3Qq46UJhYcpsCfHRfE5MBQo | 2026-02-14T18:57:26+00:00
```

## Pipeline Execution Process

### Automatic Workflow

```
Developer → Push Code → S3 source.zip
                           ↓
                    Source Stage
                     (Extract)
                           ↓
                    Build Stage
         (Docker build → ECR push → Export k8s/ artifacts)
                           ↓
                    Deploy Stage
              (kubectl apply → EKS update)
```

### Manual Trigger

```bash
aws codepipeline start-pipeline-execution \
  --name claim-api-pipeline \
  --region us-east-1 \
  --profile org-demo
```

### Monitoring

```bash
# Check overall status
aws codepipeline get-pipeline-state \
  --name claim-api-pipeline \
  --region us-east-1 \
  --profile org-demo

# View build logs
aws logs tail /aws/codebuild/claim-api-build \
  --since 10m \
  --region us-east-1 \
  --profile org-demo

# View deploy logs
aws logs tail /aws/codebuild/claim-api-deploy \
  --since 10m \
  --region us-east-1 \
  --profile org-demo
```

## Testing the Pipeline

### Test 1: Source Update
```bash
# Update source code
cd /Users/833076/.../cna-introspect-2
zip -r /tmp/source.zip . -x "*.git*" -x "*node_modules*"

# Upload to S3 (triggers pipeline if configured)
aws s3 cp /tmp/source.zip \
  s3://claim-api-artifacts-335444506576/source.zip \
  --profile org-demo
```

### Test 2: Manual Trigger
```bash
# Trigger pipeline execution
EXECUTION_ID=$(aws codepipeline start-pipeline-execution \
  --name claim-api-pipeline \
  --region us-east-1 \
  --profile org-demo \
  --query 'pipelineExecutionId' \
  --output text)

echo "Execution ID: $EXECUTION_ID"

# Wait 2-3 minutes for all stages to complete
sleep 120

# Check status
aws codepipeline get-pipeline-state \
  --name claim-api-pipeline \
  --region us-east-1 \
  --profile org-demo \
  --query 'stageStates[*].[stageName,latestExecution.status]' \
  --output table
```

### Test 3: Verify Deployment
```bash
# Check pods
kubectl get pods -l app=claim-api

# Check service
kubectl get svc claim-api

# Test API endpoint
curl https://i21ffci3hk.execute-api.us-east-1.amazonaws.com/prod/claims/CLM-1001
```

## Timeline of Troubleshooting

| Time | Action | Result |
|------|--------|--------|
| 18:57 | Enable S3 versioning | ✅ Versioning enabled |
| 18:57 | Upload source.zip | ✅ Version ID assigned |
| 18:58 | Start pipeline execution #1 | ❌ Build stage failed (ECR login) |
| 19:00 | Fix buildspec ECR login syntax | ✅ Buildspec corrected |
| 19:01 | Start pipeline execution #2 | ⚠️ Build succeeded, Deploy failed (buildspec not found) |
| 19:02 | Add buildspec-deploy.yml to artifacts | ✅ Artifacts updated |
| 19:03 | Start pipeline execution #3 | ✅ **All stages succeeded!** |

## Performance Metrics

**Latest Successful Execution**: `84eeba59-6b19-4a92-8b36-8dfffe5a6706`

- **Source Stage**: ~5 seconds
- **Build Stage**: ~60-90 seconds (Docker build + ECR push)
- **Deploy Stage**: ~30-40 seconds (kubectl apply)
- **Total Pipeline Duration**: ~2-3 minutes

## Lessons Learned

1. **S3 Versioning is Mandatory**: CodePipeline S3 source actions require bucket versioning to be enabled

2. **Buildspec Syntax Matters**: Command substitution `$()` should only be used when you need to capture output, not for simple command execution

3. **Artifact Dependencies**: Downstream stages must receive all required files via artifacts from upstream stages

4. **IAM Propagation**: Allow 30-60 seconds for IAM policy changes to propagate before retrying operations

5. **Incremental Debugging**: Fix one issue at a time, verify, then proceed to the next stage

## Recommendations

### For Production Use

1. **Enable CloudWatch Events**: Configure automatic pipeline triggers on S3 changes
   ```yaml
   EventPattern:
     source:
       - aws.s3
     detail-type:
       - AWS API Call via CloudTrail
     detail:
       eventName:
         - PutObject
   ```

2. **Add Manual Approval**: Insert approval stage between Build and Deploy for production:
   ```yaml
   - Name: Approval
     Actions:
       - Name: ManualApproval
         ActionTypeId:
           Category: Approval
           Owner: AWS
           Provider: Manual
   ```

3. **Implement Versioned Tags**: Use commit SHA or semantic versioning for Docker images instead of `:latest`

4. **Add Testing Stages**: Insert automated testing between Build and Deploy

5. **Enable Pipeline Notifications**: Configure SNS topics for pipeline status changes

## Console Access

**CodePipeline Console**:
https://console.aws.amazon.com/codesuite/codepipeline/pipelines/claim-api-pipeline/view?region=us-east-1

**CodeBuild Projects**:
- Build: https://console.aws.amazon.com/codesuite/codebuild/projects/claim-api-build
- Deploy: https://console.aws.amazon.com/codesuite/codebuild/projects/claim-api-deploy

**CloudWatch Logs**:
- Build Logs: `/aws/codebuild/claim-api-build`
- Deploy Logs: `/aws/codebuild/claim-api-deploy`

## References

- [pipelines/README.md](pipelines/README.md) - Pipeline usage guide
- [pipelines/buildspec-build.yml](pipelines/buildspec-build.yml) - Build specification
- [pipelines/buildspec-deploy.yml](pipelines/buildspec-deploy.yml) - Deploy specification
- [scripts/deploy-pipeline.sh](scripts/deploy-pipeline.sh) - Pipeline creation script
- [scripts/fix-pipeline-permissions.sh](scripts/fix-pipeline-permissions.sh) - Permission fix script
- [DEPLOYMENT.md](DEPLOYMENT.md) - Overall deployment guide
- [PIPELINE-STATUS.md](PIPELINE-STATUS.md) - Initial pipeline status document

---

**Document Created**: 2026-02-14
**Last Pipeline Success**: 2026-02-14 19:03 UTC
**Status**: Production Ready ✅
