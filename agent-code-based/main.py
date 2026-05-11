"""
Customer Support Agent — Code-based (Strands Agents + AgentCore Gateway)
Uses Amazon Nova Pro via Bedrock and connects to the order lookup tool via Gateway.
"""
from strands import Agent
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands.models.bedrock import BedrockModel
from strands.tools.mcp.mcp_client import MCPClient
from mcp.client.streamable_http import streamablehttp_client

SYSTEM_PROMPT = """You are a helpful customer support agent for an electronics store. Use the lookup_order tool to find order details."""

GATEWAY_URL = "GATEWAY_URL_PLACEHOLDER"

app = BedrockAgentCoreApp()
log = app.logger

_agent = None

def get_or_create_agent():
    global _agent
    if _agent is None:
        model = BedrockModel(model_id="us.amazon.nova-pro-v1:0")
        tools = []
        if GATEWAY_URL and GATEWAY_URL != "GATEWAY_URL_PLACEHOLDER":
            mcp_client = MCPClient(lambda: streamablehttp_client(GATEWAY_URL))
            tools.append(mcp_client)
        _agent = Agent(model=model, system_prompt=SYSTEM_PROMPT, tools=tools)
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
