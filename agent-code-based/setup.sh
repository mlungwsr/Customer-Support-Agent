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

# Step 1: Create the project with a Strands code-based agent
echo ""
echo "==> Step 1: Creating Strands agent project..."
agentcore create \
  --name CSAgent \
  --framework Strands \
  --model-provider Bedrock \
  --memory none

cd CSAgent

# Set deployment target (not auto-populated in non-interactive mode)
cat > agentcore/aws-targets.json << 'EOF'
[
  {
    "name": "default",
    "account": "463348350759",
    "region": "us-west-2"
  }
]
EOF

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

# Step 3: First deploy to create the Gateway and get its URL
echo ""
echo "==> Step 4: Deploying (first pass to create Gateway)..."
agentcore deploy --yes

# Step 4: Get Gateway URL and update the MCP client
echo ""
echo "==> Step 5: Configuring agent to use Gateway..."
GATEWAY_URL=$(agentcore status --json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for gw in data.get('gateways', []):
    if 'OrderLookupGateway' in str(gw):
        print(gw.get('url', ''))
        break
" 2>/dev/null || echo "")

# If we couldn't parse it from JSON, extract from deploy output
if [ -z "$GATEWAY_URL" ]; then
  GATEWAY_URL=$(grep -r "GatewayOrderLookupGatewayUrlOutput" agentcore/.cli/ 2>/dev/null | grep -o 'https://[^"]*' | head -1 || echo "")
fi

if [ -n "$GATEWAY_URL" ]; then
  echo "   Gateway URL: $GATEWAY_URL"
  # Update the MCP client to point at our Gateway
  cat > app/CSAgent/mcp_client/client.py << PYEOF
import os
import logging
from mcp.client.streamable_http import streamablehttp_client
from strands.tools.mcp.mcp_client import MCPClient

logger = logging.getLogger(__name__)

GATEWAY_MCP_ENDPOINT = "$GATEWAY_URL"

def get_streamable_http_mcp_client() -> MCPClient:
    """Returns an MCP Client connected to the AgentCore Gateway"""
    return MCPClient(lambda: streamablehttp_client(GATEWAY_MCP_ENDPOINT))
PYEOF

  # Update system prompt and remove example tool
  cat > app/CSAgent/main.py << 'PYEOF'
from strands import Agent
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from model.load import load_model
from mcp_client.client import get_streamable_http_mcp_client

app = BedrockAgentCoreApp()
log = app.logger

mcp_clients = [get_streamable_http_mcp_client()]
tools = []
for mcp_client in mcp_clients:
    if mcp_client:
        tools.append(mcp_client)

_agent = None

def get_or_create_agent():
    global _agent
    if _agent is None:
        _agent = Agent(
            model=load_model(),
            system_prompt="""You are a helpful customer support agent for an electronics store. Use the lookup_order tool to find order details.""",
            tools=tools
        )
    return _agent

@app.entrypoint
async def invoke(payload, context):
    log.info("Invoking Agent.....")
    agent = get_or_create_agent()
    stream = agent.stream_async(payload.get("prompt"))
    async for event in stream:
        if "data" in event and isinstance(event["data"], str):
            yield event["data"]

if __name__ == "__main__":
    app.run()
PYEOF

  # Update model to Nova Pro
  cat > app/CSAgent/model/load.py << 'PYEOF'
from strands.models.bedrock import BedrockModel

def load_model() -> BedrockModel:
    """Get Bedrock model client using IAM credentials."""
    return BedrockModel(model_id="us.amazon.nova-pro-v1:0")
PYEOF

  # Redeploy with updated code
  echo ""
  echo "==> Step 6: Redeploying with Gateway connection..."
  agentcore deploy --yes
else
  echo "   WARNING: Could not determine Gateway URL. Update mcp_client/client.py manually."
fi

echo ""
echo "============================================"
echo " Code-based agent deployed!"
echo " Test with:"
echo "   cd CSAgent"
echo "   agentcore invoke --stream --prompt \"Look up order ORD-1001\""
echo "============================================"
