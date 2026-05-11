#!/usr/bin/env bash
# ============================================================
# Setup script for the AgentCore Harness-based agent
# This creates the project, gateway, target, and deploys
# ============================================================
set -euo pipefail

REGION="us-west-2"
LAMBDA_ARN="arn:aws:lambda:us-west-2:463348350759:function:customer-order-lookup"
TOOLS_SCHEMA="$(cd "$(dirname "$0")" && pwd)/../backend/tools.json"

echo "============================================"
echo " AgentCore Harness Agent Setup"
echo "============================================"

# Step 1: Create the project with a default Strands agent
echo ""
echo "==> Step 1: Creating project..."
agentcore create \
  --name CSAgent \
  --defaults

cd CSAgent

# Step 2: Add a Gateway with the Lambda target
echo ""
echo "==> Step 2: Adding Gateway..."
agentcore add gateway \
  --name OrderLookupGateway \
  --authorizer-type NONE \
  --runtimes CSAgent

echo ""
echo "==> Step 3: Adding Lambda target to Gateway..."
agentcore add gateway-target \
  --name OrderLookupTarget \
  --type lambda-function-arn \
  --lambda-arn "$LAMBDA_ARN" \
  --tool-schema-file "$TOOLS_SCHEMA" \
  --gateway OrderLookupGateway

# Step 3: Deploy
echo ""
echo "==> Step 4: Deploying..."
agentcore deploy

echo ""
echo "============================================"
echo " Agent deployed!"
echo " Test with:"
echo "   agentcore invoke --prompt \"Look up order ORD-1001\""
echo ""
echo " Or use the boto3 harness invoke script:"
echo "   python invoke_harness.py \"Look up order ORD-1001\""
echo "============================================"
