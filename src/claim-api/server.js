const express = require("express");
const fs = require("fs");
const path = require("path");
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand } = require("@aws-sdk/lib-dynamodb");
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { BedrockRuntimeClient, InvokeModelCommand } = require("@aws-sdk/client-bedrock-runtime");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const REGION = process.env.AWS_REGION || "us-east-1";
const CLAIMS_TABLE = process.env.CLAIMS_TABLE || "claims";
const NOTES_BUCKET = process.env.NOTES_BUCKET || "claim-notes";
const BEDROCK_MODEL_ID = process.env.BEDROCK_MODEL_ID || "anthropic.claude-3-sonnet-20240229-v1:0";
const USE_MOCKS = process.env.MOCK_DATA === "true";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));
const s3 = new S3Client({ region: REGION });
const bedrock = new BedrockRuntimeClient({ region: REGION });

function readMockJson(fileName) {
  const filePath = path.join(__dirname, "..", "..", "mocks", fileName);
  const raw = fs.readFileSync(filePath, "utf-8");
  return JSON.parse(raw);
}

async function getClaimFromDynamo(id) {
  const command = new GetCommand({
    TableName: CLAIMS_TABLE,
    Key: { id }
  });
  const result = await ddb.send(command);
  return result.Item || null;
}

async function getNotesFromS3(id) {
  const command = new GetObjectCommand({
    Bucket: NOTES_BUCKET,
    Key: `${id}.txt`
  });
  const result = await s3.send(command);
  return await result.Body.transformToString();
}

async function invokeBedrock(notes) {
  const prompt = {
    overall: `Summarize the following claim notes in 5 bullet points. Notes: ${notes}`,
    customer: `Write a customer-facing summary using empathetic tone (2-4 sentences). Notes: ${notes}`,
    adjuster: `Provide an adjuster-focused summary highlighting risks and missing info. Notes: ${notes}`,
    nextStep: `Suggest the next best action in one sentence. Notes: ${notes}`
  };

  const body = JSON.stringify({
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 512,
    temperature: 0.2,
    messages: [
      {
        role: "user",
        content: `Return JSON with keys overall, customer, adjuster, nextStep. Use these prompts: ${JSON.stringify(prompt)}`
      }
    ]
  });

  const command = new InvokeModelCommand({
    modelId: BEDROCK_MODEL_ID,
    contentType: "application/json",
    accept: "application/json",
    body
  });

  const response = await bedrock.send(command);
  const payload = JSON.parse(Buffer.from(response.body).toString("utf-8"));
  const text = payload?.content?.[0]?.text || "{}";
  return JSON.parse(text);
}

app.get("/claims/health", (req, res) => {
  res.json({ status: "ok" });
});

app.get("/claims/:id", async (req, res) => {
  try {
    const { id } = req.params;
    if (USE_MOCKS) {
      const claims = readMockJson("claims.json");
      const claim = claims.find((c) => c.id === id);
      return claim ? res.json(claim) : res.status(404).json({ message: "Not found" });
    }

    const claim = await getClaimFromDynamo(id);
    return claim ? res.json(claim) : res.status(404).json({ message: "Not found" });
  } catch (error) {
    res.status(500).json({ message: "Internal error", error: error.message });
  }
});

app.post("/claims/:id/summarize", async (req, res) => {
  try {
    const { id } = req.params;
    let notes;

    if (USE_MOCKS) {
      const notesData = readMockJson("notes.json");
      const note = notesData.find((n) => n.id === id);
      notes = note?.notes || "";
    } else {
      notes = await getNotesFromS3(id);
    }

    if (!notes) {
      return res.status(404).json({ message: "No notes found" });
    }

    const summary = await invokeBedrock(notes);
    return res.json({ id, ...summary });
  } catch (error) {
    res.status(500).json({ message: "Internal error", error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Claim API listening on port ${PORT}`);
});
