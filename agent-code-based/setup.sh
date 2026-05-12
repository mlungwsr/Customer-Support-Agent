#!/usr/bin/env bash
# ============================================================
# Setup script for the AgentCore Code-based agent (Strands)
# Uses the shared Gateway created by the backend deploy.
# ============================================================
set -euo pipefail

REGION="us-west-2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GATEWAY_OUTPUT="$SCRIPT_DIR/../backend/gateway-output.json"

# Read Gateway URL from backend output
if [ ! -f "$GATEWAY_OUTPUT" ]; then
  echo "ERROR: backend/gateway-output.json not found."
  echo "Run 'cd backend && bash scripts/deploy.sh' first."
  exit 1
fi

GATEWAY_URL=$(python3 -c "import json; print(json.load(open('$GATEWAY_OUTPUT'))['gatewayUrl'])")
echo "Using shared Gateway: $GATEWAY_URL"

echo "============================================"
echo " AgentCore Code-Based Agent Setup"
echo "============================================"

# Step 1: Create the project
echo ""
echo "==> Step 1: Creating Strands agent project..."
agentcore create \
  --name CSAgent \
  --framework Strands \
  --model-provider Bedrock \
  --memory none

cd CSAgent

# Set deployment target
cat > agentcore/aws-targets.json << 'EOF'
[
  {
    "name": "default",
    "account": "463348350759",
    "region": "us-west-2"
  }
]
EOF

# Step 2: Configure agent code to use shared Gateway
echo ""
echo "==> Step 2: Configuring agent code..."

cat > app/CSAgent/mcp_client/client.py << PYEOF
import os
import logging
from mcp.client.streamable_http import streamablehttp_client
from strands.tools.mcp.mcp_client import MCPClient

logger = logging.getLogger(__name__)

GATEWAY_MCP_ENDPOINT = "$GATEWAY_URL"

def get_streamable_http_mcp_client() -> MCPClient:
    """Returns an MCP Client connected to the shared AgentCore Gateway"""
    return MCPClient(lambda: streamablehttp_client(GATEWAY_MCP_ENDPOINT))
PYEOF

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

cat > app/CSAgent/model/load.py << 'PYEOF'
from strands.models.bedrock import BedrockModel

def load_model() -> BedrockModel:
    """Get Bedrock model client using IAM credentials."""
    return BedrockModel(model_id="us.amazon.nova-pro-v1:0")
PYEOF

# Step 3: Deploy
echo ""
echo "==> Step 3: Deploying..."
agentcore deploy --yes

echo ""
echo "============================================"
echo " Code-based agent deployed!"
echo " Test with:"
echo "   cd CSAgent"
echo "   agentcore invoke --stream --prompt \"Look up order ORD-1001\""
echo "============================================"
