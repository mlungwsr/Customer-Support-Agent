# Agent Harness (Managed — No Orchestration Code)

The managed harness requires **no Python code** — just configuration.
Connects to the shared Gateway created by the backend deploy.

## Prerequisites

- Backend deployed (`cd backend && bash scripts/deploy.sh`)
- `backend/gateway-output.json` exists with the Gateway ARN
- AgentCore CLI (preview): `npm install -g @aws/agentcore@preview`

## Create the Harness

### Option A: One-Liner (Non-Interactive)

```bash
cd agent-harness
agentcore create --name SupportAgent --model-provider bedrock --model-id us.amazon.nova-pro-v1:0 --no-harness-memory
cd SupportAgent
```

### Option B: Interactive Wizard (Better for Demo Visuals)

```bash
cd agent-harness
agentcore create
# → Project name: CustomerSupport
# → Project type: Harness
# → Harness name: SupportAgent
# → Model provider: Bedrock
cd CustomerSupport
```

## Connect the Shared Gateway

Get the Gateway ARN from the backend output:

```bash
GATEWAY_ARN=$(python3 -c "import json; print(json.load(open('../../backend/gateway-output.json'))['gatewayArn'])")
echo $GATEWAY_ARN
```

Add it as a tool to the harness:

```bash
agentcore add tool --harness SupportAgent \
  --type agentcore_gateway \
  --name OrderLookupGateway \
  --gateway-arn "$GATEWAY_ARN"
```

## Deploy

```bash
agentcore deploy
```

## Invoke

```bash
SESSION="demo-session-2026-06-10-festival01"
agentcore invoke --harness SupportAgent \
  --model-id us.amazon.nova-pro-v1:0 \
  --system-prompt "You are a helpful customer support agent for an electronics store. Use the lookup_order tool to find order details." \
  --session-id "$SESSION" \
  "Look up order ORD-1001"
```

Or use the standalone invoke script:

```bash
python invoke_harness.py "What's the status of order ORD-1003?"
```

## Key Difference from Code-Based

- **No Python orchestration code** — no `main.py`, no framework
- **Config only** — model, tools, prompt are all declared, not coded
- **Override at invoke time** — swap model or prompt per call without redeploying
- **Same Gateway** — uses the same backend Gateway as the code-based agent

## Cleanup

```bash
agentcore remove all
agentcore deploy --yes
```
