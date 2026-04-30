#!/usr/bin/env bash
# ============================================================
# Setup script for the AgentCore Code-based agent (Strands)
# ============================================================
set -euo pipefail

REGION="us-west-2"
LAMBDA_ARN="arn:aws:lambda:us-west-2:463348350759:function:customer-order-lookup"
TOOLS_SCHEMA="../backend/tools.json"

echo "============================================"
echo " AgentCore Code-Based Agent Setup"
echo "============================================"

# Step 1: Create the code-based project with Strands
echo ""
echo "==> Step 1: Creating Strands agent project..."
agentcore create \
  --name CustomerSupportCodeAgent \
  --framework Strands \
  --model-provider Bedrock \
  --memory none \
  --build CodeZip

# Step 2: Move into the project
cd CustomerSupportCodeAgent

# Step 3: Add a Gateway (reuse the same pattern)
echo ""
echo "==> Step 2: Adding Gateway..."
agentcore add gateway \
  --name OrderLookupGateway \
  --authorizer-type NONE \
  --runtimes CustomerSupportCodeAgent

echo ""
echo "==> Step 3: Adding Lambda target to Gateway..."
agentcore add gateway-target \
  --name OrderLookupTarget \
  --type lambda-function-arn \
  --lambda-arn "$LAMBDA_ARN" \
  --tool-schema-file "$TOOLS_SCHEMA" \
  --gateway OrderLookupGateway

# Step 4: Copy our custom agent code
echo ""
echo "==> Step 4: Applying custom agent code..."
cp ../main.py app/CustomerSupportCodeAgent/main.py

# Step 5: Deploy
echo ""
echo "==> Step 5: Deploying..."
agentcore deploy

echo ""
echo "============================================"
echo " Code-based agent deployed!"
echo " Test with:"
echo "   agentcore invoke --prompt \"Look up order ORD-1001\""
echo "============================================"
