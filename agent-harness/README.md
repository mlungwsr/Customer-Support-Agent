# Agent Harness (Managed — No Orchestration Code)

The managed harness requires **no Python code** — just configuration.
There are two ways to create it:

## Option A: One-Liner (Non-Interactive)

```bash
npm install -g @aws/agentcore@preview

agentcore create --name SupportAgent --model-provider bedrock --model-id us.amazon.nova-pro-v1:0
cd SupportAgent
```

## Option B: Interactive Wizard (Better for Demo Visuals)

```bash
agentcore create
```

When prompted:
1. **Project name:** `CustomerSupport`
2. **Project type:** Select **Harness**
3. **Harness name:** `SupportAgent`
4. **Model provider:** Select **Bedrock**
5. **Environment:** Default
6. **Memory:** None (or short-term for demo)

```bash
cd CustomerSupport
```

## Add Gateway and Deploy

```bash
# Add Gateway with the order lookup Lambda
agentcore add gateway --name OrderLookupGateway --authorizer-type NONE
agentcore add gateway-target --name OrderLookupTarget \
  --type lambda-function-arn \
  --lambda-arn arn:aws:lambda:us-west-2:463348350759:function:customer-order-lookup \
  --tool-schema-file ../../backend/tools.json \
  --gateway OrderLookupGateway

# Connect the Gateway as a tool to the harness
agentcore add tool --harness SupportAgent \
  --type agentcore_gateway \
  --name OrderLookupGateway \
  --gateway OrderLookupGateway

# Deploy
agentcore deploy
```

## Invoke the Harness

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
