#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE=${AWS_PROFILE:-org-demo}
AWS_REGION=${AWS_REGION:-us-east-1}
CLAIMS_TABLE=${CLAIMS_TABLE:-claims}
NOTES_BUCKET=${NOTES_BUCKET:-claim-notes-bucket}

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CLAIMS_JSON="$ROOT_DIR/mocks/claims.json"
NOTES_JSON="$ROOT_DIR/mocks/notes.json"

if ! aws dynamodb describe-table --table-name "$CLAIMS_TABLE" --region "$AWS_REGION" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
  aws dynamodb create-table \
    --table-name "$CLAIMS_TABLE" \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"
fi

if ! aws s3api head-bucket --bucket "$NOTES_BUCKET" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$NOTES_BUCKET" --profile "$AWS_PROFILE"
  else
    aws s3api create-bucket \
      --bucket "$NOTES_BUCKET" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION" \
      --region "$AWS_REGION" \
      --profile "$AWS_PROFILE"
  fi
fi

ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json, os, tempfile, subprocess, sys

profile = os.environ.get("AWS_PROFILE", "org-demo")
region = os.environ.get("AWS_REGION", "us-east-1")
claims_table = os.environ.get("CLAIMS_TABLE", "claims")
notes_bucket = os.environ.get("NOTES_BUCKET", "claim-notes-bucket")
root = os.environ.get("ROOT_DIR")
if not root:
  raise RuntimeError("ROOT_DIR not set")
claims_json = os.path.join(root, "mocks", "claims.json")
notes_json = os.path.join(root, "mocks", "notes.json")

with open(claims_json) as f:
    claims = json.load(f)

request_items = {claims_table: []}
for c in claims:
    item = {k: {"S": str(v)} if isinstance(v, str) else {"N": str(v)} for k, v in c.items()}
    request_items[claims_table].append({"PutRequest": {"Item": item}})

with tempfile.NamedTemporaryFile(mode="w", delete=False) as tf:
    json.dump(request_items, tf)
    tf.flush()
    subprocess.check_call([
        "aws", "dynamodb", "batch-write-item",
        "--request-items", f"file://{tf.name}",
        "--region", region,
        "--profile", profile
    ])

with open(notes_json) as f:
    notes = json.load(f)

for n in notes:
  key = f"{n['id']}.txt"
  body = n["notes"]
  with tempfile.NamedTemporaryFile(mode="w", delete=False) as nf:
    nf.write(body)
    nf.flush()
    subprocess.run([
      "aws", "s3api", "put-object",
      "--bucket", notes_bucket,
      "--key", key,
      "--body", nf.name,
      "--region", region,
      "--profile", profile
    ], check=True)

PY

echo "✅ Seeded DynamoDB table '$CLAIMS_TABLE' and S3 bucket '$NOTES_BUCKET' using profile '$AWS_PROFILE'"
