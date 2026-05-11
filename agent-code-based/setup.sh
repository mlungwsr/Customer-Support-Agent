#!/usr/bin/env bash
# ============================================================
# Setup script for the AgentCore Code-based agent (Strands)
# ============================================================
set -euo pipefail

REGION="us-west-2"
LAMBDA_ARN="arn:aws:lambda:us-west-2:463348350759:function:customer-order-lookup"
TOOLS_SCHEMA="$(cd "$(dirname "$0")" && pwd)/../backend/tools.json"

echo "============================================"
echo " AgentCore Code-Based Agent Setup"
echo "============================================"

# Step 1: Create the project with a default Strands agent
echo ""
echo "==> Step 1: Creating Strands agent project..."
agentcore create \
  --name CSAgent \
  --defaults

cd CSAgent

# Step 2: Add a Gateway
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

# Step 3: Apply custom agent code
echo ""
echo "==> Step 4: Applying custom agent code..."
cp ../main.py app/CSAgent/main.py

# Step 4: Update MCP client to point at Gateway (URL will be set after deploy)
echo ""
echo "==> Step 5: Deploying..."
agentcore deploy --yes

# Get Gateway URL and update MCP client
GATEWAY_URL=$(agentcore status --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('gateways',{}).get('OrderLookupGateway',{}).get('url',''))" 2>/dev/null || echo "")
if [ -n "$GATEWAY_URL" ]; then
  sed -i '' "s|GATEWAY_URL_PLACEHOLDER|$GATEWAY_URL|g" app/CSAgent/mcp_client/client.py 2>/dev/null || true
fi

echo ""
echo "============================================"
echo " Code-based agent deployed!"
echo " Test with:"
echo "   cd CSAgent"
echo "   agentcore invoke --stream --prompt \"Look up order ORD-1001\""
echo "============================================"
