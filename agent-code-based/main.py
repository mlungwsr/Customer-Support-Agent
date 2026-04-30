"""
Customer Support Agent — Code-based (Strands Agents + AgentCore Gateway)
Uses Amazon Nova Pro via Bedrock and connects to the order lookup tool via Gateway.
"""
import os
from strands import Agent
from strands.models import BedrockModel
from strands.tools.mcp.mcp_client import MCPClient
from mcp.client.streamable_http import streamablehttp_client

SYSTEM_PROMPT = """You are a friendly and professional customer support agent for an online electronics store.

You can look up customer orders using their order ID (e.g., ORD-1001).

When a customer asks about an order:
1. Ask for their order ID if they haven't provided one
2. Look up the order using the lookup_order tool
3. Provide a clear, helpful summary of the order status

Be concise, empathetic, and helpful. If an order has issues (cancelled, return requested), acknowledge the situation and offer assistance."""

GATEWAY_URL = os.environ.get("GATEWAY_URL", "")


def handler(event, context):
    """AgentCore Runtime entrypoint."""
    prompt = event.get("prompt", "")
    session_id = event.get("session_id", "default")

    model = BedrockModel(model_id="us.amazon.nova-pro-v1:0", streaming=True)

    if GATEWAY_URL:
        mcp_client = MCPClient(lambda: streamablehttp_client(GATEWAY_URL))
        with mcp_client:
            tools = list(mcp_client.list_tools_sync())
            agent = Agent(model=model, tools=tools, system_prompt=SYSTEM_PROMPT)
            result = agent(prompt)
            return {"response": str(result)}
    else:
        agent = Agent(model=model, system_prompt=SYSTEM_PROMPT)
        result = agent(prompt)
        return {"response": str(result)}
