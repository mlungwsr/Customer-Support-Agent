# Agent Code-Based (Strands Agents Framework)

Full-control agent with Python orchestration code, using the **Strands Agents** framework.
Connects to the shared Gateway created by the backend deploy.

## Prerequisites

- Backend deployed (`cd backend && bash scripts/deploy.sh`)
- `backend/gateway-output.json` exists with the Gateway URL
- AgentCore CLI installed: `npm install -g @aws/agentcore`

## Setup

```bash
cd agent-code-based
./setup.sh
```

This will:
1. Create a Strands agent project (`CSAgent/`)
2. Configure the MCP client to point at the shared Gateway
3. Set Amazon Nova Pro as the model
4. Deploy to AgentCore Runtime

## Test

```bash
cd CSAgent
agentcore invoke --stream --prompt "Look up order ORD-1001"
agentcore invoke --stream --prompt "What happened with order 1004?"
```

## How It Works

Unlike the Harness agent, you have **full control over the orchestration loop**:

```
app/CSAgent/
├── main.py              # Agent entrypoint — you control the loop
├── model/load.py        # Model configuration (Nova Pro)
├── mcp_client/client.py # MCP client → shared Gateway URL
└── pyproject.toml       # Python dependencies
```

The agent connects to the same Gateway as the Harness agent, but the orchestration
(model calls, tool routing, response formatting) is all in your Python code.

## Key Difference from Harness

| | Harness | Code-Based |
|---|---|---|
| Orchestration | AgentCore manages | You write in Python |
| Model config | `--model-id` at invoke time | `model/load.py` |
| System prompt | `--system-prompt` at invoke time | Hardcoded in `main.py` |
| Tools | `agentcore add tool` | MCP client in code |
| Flexibility | Config changes | Full code control |

## Cleanup

```bash
cd CSAgent
agentcore remove all
agentcore deploy --yes
```
