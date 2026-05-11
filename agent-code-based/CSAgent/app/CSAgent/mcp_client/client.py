import os
import logging
from mcp.client.streamable_http import streamablehttp_client
from strands.tools.mcp.mcp_client import MCPClient

logger = logging.getLogger(__name__)

GATEWAY_MCP_ENDPOINT = os.environ.get(
    "GATEWAY_URL",
    "https://csagent-orderlookupgateway-yphifeeo7p.gateway.bedrock-agentcore.us-west-2.amazonaws.com/mcp"
)

def get_streamable_http_mcp_client() -> MCPClient:
    """Returns an MCP Client connected to the AgentCore Gateway"""
    return MCPClient(lambda: streamablehttp_client(GATEWAY_MCP_ENDPOINT))
