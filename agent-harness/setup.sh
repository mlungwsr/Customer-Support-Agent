#!/usr/bin/env bash
# ============================================================
# Setup script for the AgentCore Harness-based agent
# This creates the project, gateway, target, and deploys
# ============================================================
set -euo pipefail

REGION="us-west-2"
LAMBDA_ARN="arn:aws:lambda:us-west-2:463348350759:function:customer-order-lookup"
TOOLS_SCHEMA="../backend/tools.json"

echo "============================================"
echo " AgentCore Harness Agent Setup"
echo "============================================"

# Step 1: Create the harness project
echo ""
echo "==> Step 1: Creating harness project..."
agentcore create \
  --name CustomerSupportAgent \
  --model-provider bedrock

# Step 2: Move into the project
cd CustomerSupportAgent

# Step 3: Add a Gateway with the Lambda target
echo ""3
echo "==> Step 2: Adding Gateway..."
agentcore add gateway \
  --name OrderLookupGateway \
  --authorizer-type NONE \
  --runtimes CustomerSupportAgent

echo ""
echo "==> Step 3: Adding Lambda target to Gateway..."
agentcore add gateway-target \
  --name OrderLookupTarget \
  --type lambda-function-arn \
  --lambda-arn "$LAMBDA_ARN" \
  --tool-schema-file "$TOOLS_SCHEMA" \
  --gateway OrderLookupGateway

# Step 4: Add the Gateway as a tool to the harness
echo ""
echo "==> Step 4: Connecting Gateway to harness..."
agentcore add tool --harness CustomerSupportAgent \
  --type agentcore_gateway \
  --name OrderLookupGateway \
  --gateway OrderLookupGateway

# Step 5: Deploy
echo ""
echo "==> Step 5: Deploying..."
agentcore deploy

echo ""
echo "============================================"
echo " Harness agent deployed!"
echo " Test with:"
echo "   agentcore invoke --harness CustomerSupportAgent \\"
echo "     --model-id us.amazon.nova-pro-v1:0 \\"
echo "     --system-prompt \"You are a helpful customer support agent for an electronics store. Use the lookup_order tool to find order details.\" \\"
echo "     --session-id \"\$(uuidgen)\" \\"
echo "     \"Look up order ORD-1001\""
echo "============================================"
